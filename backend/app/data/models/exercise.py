"""ORM-модель упражнения."""

from sqlalchemy import Boolean, Integer, String, UniqueConstraint, true, false
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.data.db import Base


class Exercise(Base):
    """Слово или фраза для тренировки произношения."""

    __tablename__ = "exercises"
    __table_args__ = (UniqueConstraint("key", name="uq_exercises_key"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    # Стабильный ключ из файла контента: по нему сид находит запись.
    key: Mapped[str] = mapped_column(String(255), nullable=False)
    text: Mapped[str] = mapped_column(String(255), nullable=False)
    stressed_text: Mapped[str | None] = mapped_column(String(255), nullable=True)
    phonemes: Mapped[list[str]] = mapped_column(JSONB, nullable=False)
    difficulty: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    category: Mapped[str] = mapped_column(
        String(16),
        default="word",
        index=True,
        nullable=False,
    )
    audience: Mapped[str] = mapped_column(
        String(8),
        default="all",
        server_default="all",
        nullable=False,
    )
    # Упражнения не удаляются: на них ссылается история попыток.
    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        server_default=true(),
        nullable=False,
    )
    # Проверено специалистом.
    reviewed: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        server_default=false(),
        nullable=False,
    )
