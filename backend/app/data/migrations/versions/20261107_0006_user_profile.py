"""Аудитория и согласие пользователя.

Revision ID: 20261107_0006
Revises: 20261107_0005
Create Date: 2026-11-07
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20261107_0006"
down_revision: str | None = "20261107_0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Добавляет выбор аудитории и версию принятого согласия."""

    op.add_column("users", sa.Column("audience", sa.String(length=8), nullable=True))
    op.add_column("users", sa.Column("consent_version", sa.Integer(), nullable=True))
    op.add_column(
        "users",
        sa.Column("consented_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    """Удаляет поля профиля."""

    for name in ("consented_at", "consent_version", "audience"):
        op.drop_column("users", name)
