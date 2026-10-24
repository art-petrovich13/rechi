"""Сценарии работы с упражнениями."""

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.data.models import Exercise
from app.exercises.dto import ExerciseCategory
from app.exercises.exceptions import ExerciseNotFoundError


async def get_random_exercise(
    db: AsyncSession,
    category: ExerciseCategory | None = None,
) -> Exercise:
    """Возвращает случайное упражнение, опционально из категории."""

    statement = select(Exercise)
    if category is not None:
        statement = statement.where(Exercise.category == category.value)
    statement = statement.order_by(func.random()).limit(1)
    exercise = await db.scalar(statement)
    if exercise is None:
        raise ExerciseNotFoundError

    return exercise
