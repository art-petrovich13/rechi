"""DTO авторизации через Telegram."""

from pydantic import Field

from app.api.v1.dto.common import ApiSchema


class TelegramAuthRequest(ApiSchema):
    """Данные авторизации, полученные из Telegram Mini App."""

    init_data: str = Field(alias="initData", min_length=1)


class UserResponse(ApiSchema):
    """Публичные данные пользователя."""

    id: int = Field(ge=1)
    first_name: str | None = None


class TelegramAuthResponse(ApiSchema):
    """JWT и пользователь после успешной авторизации."""

    token: str = Field(min_length=1)
    user: UserResponse
