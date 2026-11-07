"""Бизнес-логика прогресса пользователя.

Средние считаются по последним попыткам, а не за всё время: иначе старые
ошибки навсегда держат звук в «слабых» и улучшение не видно.
"""

from collections import defaultdict

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.numbers import mean_score
from app.data.models import Attempt, User
from app.progress.dto import ProgressSummary, WeakPhoneme


WEAK_PHONEME_SCORE_THRESHOLD = 70
# Сколько последних оценок звука входит в среднее.
RECENT_WINDOW = 10
# Сколько последних попыток читать: хватает на два окна по любому звуку.
HISTORY_LIMIT = 300


async def get_user_progress(db: AsyncSession, user: User) -> ProgressSummary:
    """Считает слабые звуки по последним попыткам пользователя."""

    attempts_count = await db.scalar(
        select(func.count()).select_from(Attempt).where(Attempt.user_id == user.id)
    )
    result = await db.scalars(
        select(Attempt.phoneme_scores)
        .where(Attempt.user_id == user.id)
        .order_by(Attempt.created_at.desc(), Attempt.id.desc())
        .limit(HISTORY_LIMIT)
    )
    chronological = list(result)[::-1]
    return build_progress_summary(
        chronological,
        attempts_count=attempts_count or 0,
    )


def build_progress_summary(
    attempts: list[dict[str, int]],
    *,
    attempts_count: int | None = None,
) -> ProgressSummary:
    """Собирает сводку из оценок звуков в хронологическом порядке."""

    scores_by_phoneme: dict[str, list[int]] = defaultdict(list)
    for phoneme_scores in attempts:
        for phoneme, score in phoneme_scores.items():
            scores_by_phoneme[phoneme].append(score)

    weak_phonemes: list[WeakPhoneme] = []
    for phoneme, scores in scores_by_phoneme.items():
        recent = scores[-RECENT_WINDOW:]
        previous = scores[-2 * RECENT_WINDOW : -RECENT_WINDOW]
        average = mean_score(recent)
        if average >= WEAK_PHONEME_SCORE_THRESHOLD:
            continue
        weak_phonemes.append(
            WeakPhoneme(
                phoneme=phoneme,
                avg_score=average,
                trend=average - mean_score(previous) if previous else None,
                samples=len(scores),
            )
        )
    weak_phonemes.sort(key=lambda item: (item.avg_score, item.phoneme))

    return ProgressSummary(
        attempts_count=len(attempts) if attempts_count is None else attempts_count,
        weak_phonemes=weak_phonemes,
    )
