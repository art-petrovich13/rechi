"""Профиль пользователя: аудитория, согласие, удаление данных."""

from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.auth import get_current_user
from app.api.dependencies.db import get_db
from app.api.v1.dto.auth import UpdateProfileRequest, UserResponse
from app.data.models import User


router = APIRouter(prefix="/me", tags=["profile"])


@router.get("", response_model=UserResponse)
async def get_profile(
    current_user: Annotated[User, Depends(get_current_user)],
) -> UserResponse:
    """Возвращает профиль текущего пользователя."""

    return UserResponse.from_user(current_user)


@router.patch("", response_model=UserResponse)
async def update_profile(
    payload: UpdateProfileRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> UserResponse:
    """Сохраняет аудиторию и принятое согласие."""

    if payload.audience is not None:
        current_user.audience = payload.audience.value
    if payload.consent_version is not None:
        current_user.consent_version = payload.consent_version
        current_user.consented_at = datetime.now(UTC)
    await db.commit()
    return UserResponse.from_user(current_user)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> Response:
    """Удаляет пользователя и все его попытки без возможности восстановления."""

    await db.delete(current_user)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
