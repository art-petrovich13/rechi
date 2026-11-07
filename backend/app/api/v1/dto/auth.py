"""DTO авторизации через Telegram."""

from pydantic import Field

from app.api.v1.dto.common import ApiSchema
from app.exercises.dto import ExerciseAudience


class TelegramAuthRequest(ApiSchema):
    """Данные авторизации, полученные из Telegram Mini App."""

    init_data: str = Field(alias="initData", min_length=1)


class UserResponse(ApiSchema):
    """Публичные данные пользователя."""

    id: int = Field(ge=1)
    first_name: str | None = None
    audience: ExerciseAudience | None = None
    consent_version: int | None = None

    @classmethod
    def from_user(cls, user: object) -> "UserResponse":
        """Собирает ответ из ORM-пользователя."""

        audience = getattr(user, "audience", None)
        return cls(
            id=getattr(user, "id"),
            first_name=getattr(user, "first_name", None),
            audience=ExerciseAudience(audience) if audience else None,
            consent_version=getattr(user, "consent_version", None),
        )


class UpdateProfileRequest(ApiSchema):
    """Изменения профиля; отсутствующие поля не трогаются."""

    audience: ExerciseAudience | None = None
    consent_version: int | None = Field(default=None, ge=1)


class TelegramAuthResponse(ApiSchema):
    """JWT и пользователь после успешной авторизации."""

    token: str = Field(min_length=1)
    user: UserResponse
