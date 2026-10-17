"""Сценарии авторизации пользователей."""

from dataclasses import dataclass

from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.telegram import validate_init_data
from app.auth.tokens import create_access_token
from app.data.models import User


@dataclass(frozen=True, slots=True)
class AuthResult:
    """Результат успешной авторизации пользователя."""

    token: str
    user: User


async def authenticate_telegram_user(
    init_data: str,
    db: AsyncSession,
) -> AuthResult:
    """Валидирует initData, сохраняет пользователя и выпускает JWT."""

    telegram_data = validate_init_data(init_data)
    telegram_user = telegram_data["user"]

    statement = (
        insert(User)
        .values(
            telegram_id=telegram_user["id"],
            first_name=telegram_user.get("first_name"),
        )
        .on_conflict_do_update(
            index_elements=[User.telegram_id],
            set_={"first_name": telegram_user.get("first_name")},
        )
        .returning(User)
    )
    user = (await db.scalars(statement)).one()
    await db.commit()

    return AuthResult(token=create_access_token(user.id), user=user)
