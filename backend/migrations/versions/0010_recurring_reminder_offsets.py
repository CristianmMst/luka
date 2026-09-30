"""recurring_reminder_offsets

Revision ID: 0010
Revises: 0009
Create Date: 2026-10-01 10:00:00.000000

Tres avisos por gasto fijo: 7, 2 y 1 dias antes del vencimiento (spec 011 SS5).
`last_reminder_days` guarda el aviso mas cercano ya enviado, para no repetir
ninguno; el indice parcial del cron deja de filtrar por `reminded_at` porque una
ocurrencia ya avisada a 7 dias sigue siendo candidata para los de 2 y 1.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0010"
down_revision: str | None = "0009"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_INDEX = "ix_recurring_occurrences_due_date_pendientes"


def upgrade() -> None:
    """Upgrade schema: agrega `last_reminder_days` y rehace el indice del cron."""
    op.add_column(
        "recurring_occurrences",
        sa.Column("last_reminder_days", sa.SmallInteger(), nullable=True),
    )
    op.create_check_constraint(
        op.f("ck_recurring_occurrences_last_reminder_days_valido"),
        "recurring_occurrences",
        "last_reminder_days IS NULL OR last_reminder_days IN (1, 2, 7)",
    )
    # Una ocurrencia ya avisada con el esquema viejo (un solo aviso, 1 o 2 dias
    # antes) no vuelve a recibir los avisos lejanos.
    op.execute(
        "UPDATE recurring_occurrences SET last_reminder_days = 1 WHERE reminded_at IS NOT NULL"
    )
    op.drop_index(_INDEX, table_name="recurring_occurrences")
    op.create_index(
        _INDEX,
        "recurring_occurrences",
        ["due_date"],
        postgresql_where=sa.text("status = 'pending'"),
    )


def downgrade() -> None:
    """Downgrade schema: vuelve al indice con `reminded_at IS NULL` y quita la columna."""
    op.drop_index(_INDEX, table_name="recurring_occurrences")
    op.create_index(
        _INDEX,
        "recurring_occurrences",
        ["due_date"],
        postgresql_where=sa.text("status = 'pending' AND reminded_at IS NULL"),
    )
    op.drop_constraint(
        op.f("ck_recurring_occurrences_last_reminder_days_valido"),
        "recurring_occurrences",
        type_="check",
    )
    op.drop_column("recurring_occurrences", "last_reminder_days")
