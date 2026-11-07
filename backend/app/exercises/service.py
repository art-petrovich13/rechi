"""Подбор следующего упражнения.

Упражнения не заканчиваются. Порядок выбора:

1. повтор — последний балл ниже порога; чередуется с новыми;
2. новое с теми же или похожими слабыми звуками;
3. просто новое по уровню сложности;
4. закрепление — давно не встречавшееся из хорошо пройденных.

Упражнения из последних попыток откладываются, чтобы «Дальше» не давало
то же самое слово сразу.
"""

from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import distinct_on
from sqlalchemy.ext.asyncio import AsyncSession

from app.data.models import Attempt, Exercise, User
from app.exercises.dto import (
    ExerciseAudience,
    ExerciseCategory,
    SelectionReason,
)
from app.exercises.exceptions import ExerciseNotFoundError
from app.phonetics.alphabet import focus_phonemes, related_phonemes
from app.progress.service import get_user_progress


REPEAT_SCORE_THRESHOLD = 70
RECENT_ATTEMPTS = 5


@dataclass(frozen=True, slots=True)
class ExerciseStats:
    """Последний результат пользователя по упражнению."""

    last_score: int
    last_at: datetime


@dataclass(frozen=True, slots=True)
class ExerciseChoice:
    """Выбранное упражнение и причина выбора."""

    exercise: Exercise
    reason: SelectionReason


async def get_next_exercise(
    db: AsyncSession,
    user: User,
    category: ExerciseCategory | None = None,
    focus: str | None = None,
    exclude_ids: Sequence[int] = (),
    audience: ExerciseAudience | None = None,
) -> ExerciseChoice:
    """Возвращает следующее упражнение пользователя."""

    statement = select(Exercise).where(Exercise.is_active.is_(True))
    if category is not None:
        statement = statement.where(Exercise.category == category.value)
    if audience is not None and audience is not ExerciseAudience.ALL:
        statement = statement.where(
            Exercise.audience.in_((ExerciseAudience.ALL.value, audience.value))
        )
    candidates = list(await db.scalars(statement))
    if focus and focus.strip():
        targets = focus_phonemes(focus)
        candidates = [
            exercise
            for exercise in candidates
            if targets.intersection(exercise.phonemes)
        ]
    excluded = set(exclude_ids)
    pool = [exercise for exercise in candidates if exercise.id not in excluded]
    if not pool:
        raise ExerciseNotFoundError

    progress = await get_user_progress(db, user)
    return choose_exercise(
        pool,
        stats=await _exercise_stats(db, user),
        recent_ids=await _recent_exercise_ids(db, user),
        weak_phonemes=[item.phoneme for item in progress.weak_phonemes],
        attempts_count=progress.attempts_count,
    )


def choose_exercise(
    pool: Sequence[Exercise],
    *,
    stats: dict[int, ExerciseStats],
    recent_ids: Iterable[int],
    weak_phonemes: Iterable[str],
    attempts_count: int,
) -> ExerciseChoice:
    """Выбирает упражнение из непустого списка кандидатов."""

    recent = set(recent_ids)
    fresh = [exercise for exercise in pool if exercise.id not in recent] or list(pool)

    repeat = sorted(
        (
            exercise
            for exercise in fresh
            if exercise.id in stats
            and stats[exercise.id].last_score < REPEAT_SCORE_THRESHOLD
        ),
        key=lambda exercise: (
            stats[exercise.id].last_score,
            stats[exercise.id].last_at,
            exercise.id,
        ),
    )
    new = [exercise for exercise in fresh if exercise.id not in stats]
    review = sorted(
        (
            exercise
            for exercise in fresh
            if exercise.id in stats
            and stats[exercise.id].last_score >= REPEAT_SCORE_THRESHOLD
        ),
        key=lambda exercise: (stats[exercise.id].last_at, exercise.id),
    )

    if repeat and (attempts_count % 2 == 0 or not new):
        return ExerciseChoice(repeat[0], SelectionReason.REPEAT)
    if new:
        weak = set(weak_phonemes)
        related = {
            sound for phoneme in weak for sound in related_phonemes(phoneme)
        } - weak

        def relevance(exercise: Exercise) -> int:
            sounds = set(exercise.phonemes)
            return 2 * len(weak & sounds) + len(related & sounds)

        best = min(
            new,
            key=lambda exercise: (-relevance(exercise), exercise.difficulty, exercise.id),
        )
        reason = SelectionReason.SIMILAR if relevance(best) else SelectionReason.NEW
        return ExerciseChoice(best, reason)
    return ExerciseChoice(review[0], SelectionReason.REVIEW)


async def _exercise_stats(db: AsyncSession, user: User) -> dict[int, ExerciseStats]:
    """Последний балл и время по каждому упражнению пользователя."""

    rows = await db.execute(
        select(Attempt.exercise_id, Attempt.score, Attempt.created_at)
        .where(Attempt.user_id == user.id)
        .ext(distinct_on(Attempt.exercise_id))
        .order_by(Attempt.exercise_id, Attempt.created_at.desc(), Attempt.id.desc())
    )
    return {
        exercise_id: ExerciseStats(last_score=score, last_at=created_at)
        for exercise_id, score, created_at in rows.all()
    }


async def _recent_exercise_ids(db: AsyncSession, user: User) -> set[int]:
    """Упражнения последних попыток."""

    rows = await db.scalars(
        select(Attempt.exercise_id)
        .where(Attempt.user_id == user.id)
        .order_by(Attempt.created_at.desc(), Attempt.id.desc())
        .limit(RECENT_ATTEMPTS)
    )
    return set(rows)


