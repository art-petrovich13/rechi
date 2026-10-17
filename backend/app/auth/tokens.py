"""Создание токенов доступа приложения."""

from datetime import UTC, datetime, timedelta

from jose import JWTError, jwt

from app.auth.exceptions import InvalidAccessTokenError
from app.core.config import settings


def create_access_token(user_id: int) -> str:
    """Создаёт JWT для авторизованного пользователя."""

    if not settings.jwt_secret:
        raise RuntimeError("JWT_SECRET is not configured")

    now = datetime.now(UTC)
    payload = {
        "sub": str(user_id),
        "iat": now,
        "exp": now + timedelta(days=settings.jwt_expire_days),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> int:
    """Проверяет JWT и возвращает идентификатор пользователя из subject."""

    if not settings.jwt_secret:
        raise RuntimeError("JWT_SECRET is not configured")

    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
        user_id = int(payload["sub"])
    except (JWTError, KeyError, TypeError, ValueError) as error:
        raise InvalidAccessTokenError("Invalid access token") from error

    if user_id < 1:
        raise InvalidAccessTokenError("Invalid access token")

    return user_id
