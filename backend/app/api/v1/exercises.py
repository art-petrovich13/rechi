"""HTTP API упражнений."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.auth import get_current_user
from app.api.dependencies.db import get_db
from app.api.v1.dto.common import ErrorResponse
from app.api.v1.dto.exercise import ExerciseResponse
from app.core.errors import ApiError
from app.data.models import User
from app.exercises.dto import ExerciseAudience, ExerciseCategory
from app.exercises.exceptions import ExerciseNotFoundError
from app.exercises.service import get_next_exercise as get_next_exercise_for_user


router = APIRouter(prefix="/exercises", tags=["exercises"])

MAX_EXCLUDED_EXERCISES = 100


@router.get(
    "/next",
    response_model=ExerciseResponse,
    responses={status.HTTP_404_NOT_FOUND: {"model": ErrorResponse}},
)
async def get_next_exercise(
    category: Annotated[ExerciseCategory | None, Query()] = None,
    focus: Annotated[str | None, Query(min_length=1, max_length=16)] = None,
    exclude_id: Annotated[
        list[int] | None,
        Query(max_length=MAX_EXCLUDED_EXERCISES),
    ] = None,
    audience: Annotated[ExerciseAudience | None, Query()] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ExerciseResponse:
    """Возвращает следующее упражнение: повтор, похожее, новое или закрепление."""

    try:
        choice = await get_next_exercise_for_user(
            db,
            current_user,
            category,
            focus,
            exclude_id or (),
            audience,
        )
    except ExerciseNotFoundError as error:
        raise ApiError(
            status.HTTP_404_NOT_FOUND,
            "No exercises match the filters",
            "no_exercises",
        ) from error

    exercise = choice.exercise
    return ExerciseResponse(
        id=exercise.id,
        text=exercise.text,
        phonemes=exercise.phonemes,
        difficulty=exercise.difficulty,
        category=ExerciseCategory(exercise.category),
        audience=ExerciseAudience(exercise.audience),
        reason=choice.reason,
    )
