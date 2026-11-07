"""Контент из файла данных и метрики попыток.

Revision ID: 20261107_0005
Revises: 20261106_0004
Create Date: 2026-11-07
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20261107_0005"
down_revision: str | None = "20261106_0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Добавляет ключ, аудиторию и статус упражнений, метрики попыток."""

    op.add_column("exercises", sa.Column("key", sa.String(length=255), nullable=True))
    op.execute("UPDATE exercises SET key = text")
    op.alter_column("exercises", "key", nullable=False)
    op.create_unique_constraint("uq_exercises_key", "exercises", ["key"])
    op.add_column(
        "exercises",
        sa.Column("stressed_text", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "exercises",
        sa.Column("audience", sa.String(length=8), nullable=False, server_default="all"),
    )
    op.add_column(
        "exercises",
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column(
        "exercises",
        sa.Column("reviewed", sa.Boolean(), nullable=False, server_default=sa.false()),
    )

    for name in ("fluency", "rhythm", "pronunciation"):
        op.add_column("attempts", sa.Column(name, sa.Integer(), nullable=True))
    op.add_column("attempts", sa.Column("duration", sa.Float(), nullable=True))
    op.create_index(
        "ix_attempts_user_id_created_at",
        "attempts",
        ["user_id", "created_at"],
    )


def downgrade() -> None:
    """Возвращает схему ревизии 0004."""

    op.drop_index("ix_attempts_user_id_created_at", table_name="attempts")
    for name in ("duration", "pronunciation", "rhythm", "fluency"):
        op.drop_column("attempts", name)
    for name in ("reviewed", "is_active", "audience", "stressed_text"):
        op.drop_column("exercises", name)
    op.drop_constraint("uq_exercises_key", "exercises", type_="unique")
    op.drop_column("exercises", "key")
