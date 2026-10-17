"""ORM-модель упражнения."""

from sqlalchemy import Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.data.db import Base


class Exercise(Base):
    """Слово или фраза для тренировки произношения."""

    __tablename__ = "exercises"

    id: Mapped[int] = mapped_column(primary_key=True)
    text: Mapped[str] = mapped_column(String(255), nullable=False)
    phonemes: Mapped[list[str]] = mapped_column(JSONB, nullable=False)
    difficulty: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
