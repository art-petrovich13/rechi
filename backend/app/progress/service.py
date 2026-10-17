"""Бизнес-логика прогресса пользователя."""

from collections import defaultdict

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.data.models import Attempt, User
from app.progress.dto import ProgressSummary, WeakPhoneme


WEAK_PHONEME_SCORE_THRESHOLD = 70


async def get_user_progress(db: AsyncSession, user: User) -> ProgressSummary:
    """Считает средние оценки слабых фонем по всем попыткам пользователя."""

    result = await db.scalars(
        select(Attempt.phoneme_scores)
        .where(Attempt.user_id == user.id)
        .order_by(Attempt.id)
    )
    attempts = list(result)
    return build_progress_summary(attempts)


def build_progress_summary(
    attempts: list[dict[str, int]],
) -> ProgressSummary:
    """Собирает сводку из сохранённых оценок фонем."""

    scores_by_phoneme: dict[str, list[int]] = defaultdict(list)
    for phoneme_scores in attempts:
        for phoneme, score in phoneme_scores.items():
            scores_by_phoneme[phoneme].append(score)

    weak_phonemes = [
        WeakPhoneme(phoneme=phoneme, avg_score=_round_average(scores))
        for phoneme, scores in scores_by_phoneme.items()
        if _round_average(scores) < WEAK_PHONEME_SCORE_THRESHOLD
    ]
    weak_phonemes.sort(key=lambda item: (item.avg_score, item.phoneme))

    return ProgressSummary(
        attempts_count=len(attempts),
        weak_phonemes=weak_phonemes,
    )


def _round_average(scores: list[int]) -> int:
    """Округляет среднюю оценку до ближайшего целого."""

    return round(sum(scores) / len(scores))
