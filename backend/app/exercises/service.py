"""Сценарии работы с упражнениями."""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.data.models import Attempt, Exercise, User
from app.exercises.dto import ExerciseCategory
from app.exercises.exceptions import ExerciseNotFoundError


async def get_next_exercise(
    db: AsyncSession,
    user: User,
    category: ExerciseCategory | None = None,
    focus: str | None = None,
    exclude_id: int | None = None,
) -> Exercise:
    """Возвращает следующее непройденное упражнение по порядку сложности."""

    attempted_ids = select(Attempt.exercise_id).where(
        Attempt.user_id == user.id
    )
    statement = select(Exercise).where(Exercise.id.not_in(attempted_ids))
    if category is not None:
        statement = statement.where(Exercise.category == category.value)
    if focus:
        statement = statement.where(
            Exercise.phonemes.contains([focus.strip().upper()])
        )
    if exclude_id is not None:
        statement = statement.where(Exercise.id != exclude_id)
    statement = statement.order_by(
        Exercise.difficulty.asc(),
        Exercise.id.asc(),
    ).limit(1)
    exercise = await db.scalar(statement)
    if exercise is None:
        raise ExerciseNotFoundError

    return exercise
