"""transaction_tombstones

Revision ID: 0012
Revises: 0011
Create Date: 2026-10-05 18:00:00.000000

Lapidas de capturas borradas (spec 004 SS2.16, SS3): borrar un movimiento capturado
deja su huella para que otra fuente de la misma compra (un correo tardio, la cola de
avisos del telefono, un `reparse`) no lo vuelva a crear. Se purgan a los 7 dias.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "0012"
down_revision: str | None = "0011"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_BANK_VALUES = "'bancolombia','nequi','davivienda','daviplata','bbva','banco_bogota','other'"
_DIRECTION_VALUES = "'debit','credit'"


def upgrade() -> None:
    """Upgrade schema: crea `transaction_tombstones`."""
    op.create_table(
        "transaction_tombstones",
        sa.Column("id", sa.Uuid(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("dedupe_key", sa.Text(), nullable=False),
        sa.Column("bank", sa.Text(), nullable=False),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("direction", sa.Text(), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("channels", postgresql.ARRAY(sa.Text()), nullable=False),
        sa.Column("origin", sa.Text(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("amount > 0", name="amount_positivo"),
        sa.CheckConstraint(f"direction IN ({_DIRECTION_VALUES})", name="direction_valido"),
        sa.CheckConstraint(f"bank IN ({_BANK_VALUES})", name="bank_valido"),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_transaction_tombstones_user_id_users",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_transaction_tombstones"),
    )
    op.create_index(
        "ix_transaction_tombstones_user_id_occurred_at",
        "transaction_tombstones",
        ["user_id", "occurred_at"],
    )
    op.create_index(
        "ix_transaction_tombstones_deleted_at", "transaction_tombstones", ["deleted_at"]
    )


def downgrade() -> None:
    """Downgrade schema: dropea `transaction_tombstones`."""
    op.drop_index("ix_transaction_tombstones_deleted_at", table_name="transaction_tombstones")
    op.drop_index(
        "ix_transaction_tombstones_user_id_occurred_at", table_name="transaction_tombstones"
    )
    op.drop_table("transaction_tombstones")
