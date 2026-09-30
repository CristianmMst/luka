"""device_tokens

Revision ID: 0009
Revises: 0008
Create Date: 2026-09-30 12:00:00.000000

Tokens de FCM para los recordatorios push de gastos fijos (spec 004 SS2.15, spec
011 SS6). `token` es unico: registrarlo con otra cuenta reasigna la fila.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0009"
down_revision: str | None = "0008"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_PLATFORM_VALUES = "'android','ios'"


def upgrade() -> None:
    """Upgrade schema: crea `device_tokens`."""
    op.create_table(
        "device_tokens",
        sa.Column("id", sa.Uuid(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("token", sa.Text(), nullable=False),
        sa.Column("platform", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(f"platform IN ({_PLATFORM_VALUES})", name="platform_valido"),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_device_tokens_user_id_users",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_device_tokens"),
        sa.UniqueConstraint("token", name="uq_device_tokens_token"),
    )
    op.create_index("ix_device_tokens_user_id", "device_tokens", ["user_id"])


def downgrade() -> None:
    """Downgrade schema: dropea `device_tokens`."""
    op.drop_index("ix_device_tokens_user_id", table_name="device_tokens")
    op.drop_table("device_tokens")
