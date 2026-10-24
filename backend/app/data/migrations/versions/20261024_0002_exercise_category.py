"""Добавляет категорию упражнения.

Revision ID: 20261024_0002
Revises: 20261017_0001
Create Date: 2026-10-24
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20261024_0002"
down_revision: str | None = "20261017_0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Добавляет category со значением word по умолчанию."""

    op.add_column(
        "exercises",
        sa.Column(
            "category",
            sa.String(length=16),
            nullable=False,
            server_default="word",
        ),
    )
    op.create_index("ix_exercises_category", "exercises", ["category"])


def downgrade() -> None:
    """Удаляет категорию."""

    op.drop_index("ix_exercises_category", table_name="exercises")
    op.drop_column("exercises", "category")
