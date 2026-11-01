"""Добавляет per-word разбор в попытки.

Revision ID: 20261024_0003
Revises: 20261024_0002
Create Date: 2026-10-24
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "20261024_0003"
down_revision: str | None = "20261024_0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Сохраняет разбор по словам вместе с попыткой."""

    op.add_column(
        "attempts",
        sa.Column(
            "words",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
    )


def downgrade() -> None:
    """Удаляет разбор по словам."""

    op.drop_column("attempts", "words")
