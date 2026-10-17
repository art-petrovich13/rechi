"""Авторизация пользователя через Telegram Mini App."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.db import get_db
from app.api.v1.dto.auth import TelegramAuthRequest, TelegramAuthResponse
from app.api.v1.dto.common import ErrorResponse
from app.auth.exceptions import InvalidInitDataError
from app.auth.service import authenticate_telegram_user


router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/telegram",
    response_model=TelegramAuthResponse,
    responses={status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponse}},
)
async def authenticate_with_telegram(
    payload: TelegramAuthRequest,
    db: AsyncSession = Depends(get_db),
) -> TelegramAuthResponse:
    """Проверяет initData, сохраняет пользователя и возвращает JWT."""

    try:
        result = await authenticate_telegram_user(payload.init_data, db)
    except InvalidInitDataError as error:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid initData",
        ) from error

    return TelegramAuthResponse(
        token=result.token,
        user={"id": result.user.id, "first_name": result.user.first_name},
    )
