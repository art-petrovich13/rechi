"""Зависимости авторизации защищённых endpoint."""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.db import get_db
from app.auth.exceptions import InvalidAccessTokenError
from app.auth.tokens import decode_access_token
from app.data.models import User


bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Возвращает пользователя из корректного Bearer JWT."""

    if credentials is None:
        raise _unauthorized()

    try:
        user_id = decode_access_token(credentials.credentials)
    except InvalidAccessTokenError as error:
        raise _unauthorized() from error

    user = await db.get(User, user_id)
    if user is None:
        raise _unauthorized()

    return user


def _unauthorized() -> HTTPException:
    """Создаёт единый ответ для ошибок Bearer-авторизации."""

    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid authentication credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
