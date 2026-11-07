"""ORM-модель пользователя."""

from datetime import datetime

from sqlalchemy import BigInteger, DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.data.db import Base


class User(Base):
    """Пользователь, авторизованный через Telegram."""

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    telegram_id: Mapped[int] = mapped_column(
        BigInteger,
        unique=True,
        nullable=False,
    )
    first_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    # child или adult; None — ещё не выбрано, клиент спросит при входе.
    audience: Mapped[str | None] = mapped_column(String(8), nullable=True)
    # Версия текста согласия, которую принял пользователь.
    consent_version: Mapped[int | None] = mapped_column(Integer, nullable=True)
    consented_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
