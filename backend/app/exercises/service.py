"""Сценарии работы с упражнениями."""

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.data.models import Exercise
from app.exercises.dto import ExerciseCategory
from app.exercises.exceptions import ExerciseNotFoundError


async def get_random_exercise(
    db: AsyncSession,
    category: ExerciseCategory | None = None,
    focus: str | None = None,
) -> Exercise:
    """Возвращает упражнение, опционально из категории и с нужным звуком."""

    statement = select(Exercise)
    if category is not None:
        statement = statement.where(Exercise.category == category.value)
    if focus:
        statement = statement.where(
            Exercise.phonemes.contains([focus.strip().upper()])
        )
    statement = statement.order_by(func.random()).limit(1)
    exercise = await db.scalar(statement)
    if exercise is None:
        raise ExerciseNotFoundError

    return exercise
