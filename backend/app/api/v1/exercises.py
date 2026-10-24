"""HTTP API упражнений."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.auth import get_current_user
from app.api.dependencies.db import get_db
from app.api.v1.dto.common import ErrorResponse
from app.api.v1.dto.exercise import ExerciseResponse
from app.data.models import User
from app.exercises.dto import ExerciseCategory
from app.exercises.exceptions import ExerciseNotFoundError
from app.exercises.service import get_random_exercise


router = APIRouter(prefix="/exercises", tags=["exercises"])


@router.get(
    "/next",
    response_model=ExerciseResponse,
    responses={status.HTTP_404_NOT_FOUND: {"model": ErrorResponse}},
)
async def get_next_exercise(
    category: Annotated[ExerciseCategory | None, Query()] = None,
    focus: Annotated[str | None, Query(min_length=1, max_length=2)] = None,
    db: AsyncSession = Depends(get_db),
    _current_user: User = Depends(get_current_user),
) -> ExerciseResponse:
    """Возвращает упражнение авторизованному пользователю."""

    try:
        exercise = await get_random_exercise(db, category, focus)
    except ExerciseNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No exercises available",
        ) from error

    return ExerciseResponse.model_validate(exercise, from_attributes=True)
