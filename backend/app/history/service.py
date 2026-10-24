"""Сценарии чтения истории попыток."""

from dataclasses import dataclass
from datetime import datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.data.models import Attempt, Exercise, User


@dataclass(frozen=True, slots=True)
class HistoryItem:
    """Одна попытка с упражнением и разбором по словам."""

    id: int
    exercise_id: int
    exercise_text: str
    category: str
    score: int
    phoneme_scores: dict[str, int]
    words: list[dict[str, Any]]
    created_at: datetime


async def get_user_history(
    db: AsyncSession,
    user: User,
    *,
    limit: int = 20,
) -> list[HistoryItem]:
    """Возвращает последние попытки пользователя."""

    result = await db.execute(
        select(Attempt, Exercise)
        .join(Exercise, Attempt.exercise_id == Exercise.id)
        .where(Attempt.user_id == user.id)
        .order_by(Attempt.created_at.desc(), Attempt.id.desc())
        .limit(limit)
    )
    return [
        HistoryItem(
            id=attempt.id,
            exercise_id=exercise.id,
            exercise_text=exercise.text,
            category=exercise.category,
            score=attempt.score,
            phoneme_scores=attempt.phoneme_scores,
            words=attempt.words or [],
            created_at=attempt.created_at,
        )
        for attempt, exercise in result.all()
    ]
