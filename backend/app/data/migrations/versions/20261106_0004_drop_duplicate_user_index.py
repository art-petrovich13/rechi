"""Удаляет индекс, дублирующий unique-ограничение telegram_id.

Revision ID: 20261106_0004
Revises: 20261024_0003
Create Date: 2026-11-06
"""

from collections.abc import Sequence

from alembic import op


revision: str = "20261106_0004"
down_revision: str | None = "20261024_0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Оставляет только unique-ограничение: оно уже создаёт индекс."""

    op.drop_index("ix_users_telegram_id", table_name="users")


def downgrade() -> None:
    """Возвращает отдельный индекс."""

    op.create_index("ix_users_telegram_id", "users", ["telegram_id"])
