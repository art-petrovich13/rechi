"""Сценарии работы с упражнениями."""

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.data.models import Exercise
from app.exercises.exceptions import ExerciseNotFoundError


async def get_random_exercise(db: AsyncSession) -> Exercise:
    """Возвращает случайное упражнение из базы данных."""

    statement = select(Exercise).order_by(func.random()).limit(1)
    exercise = await db.scalar(statement)
    if exercise is None:
        raise ExerciseNotFoundError

    return exercise
