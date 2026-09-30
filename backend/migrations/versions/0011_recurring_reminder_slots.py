"""recurring_reminder_slots

Revision ID: 0011
Revises: 0010
Create Date: 2026-09-30 16:00:00.000000

Cuatro avisos por gasto fijo (spec 011 SS5): 7 y 2 dias antes a las 09:00, y el dia
antes a las 09:00 y a las 17:00. `last_reminder_slot` (1-4) reemplaza a
`last_reminder_days` (7, 2 o 1) de la 0010: 7 -> 1, 2 -> 2 y 1 -> 3, porque el de
1 dia de antes era el de las 09:00. El indice parcial del cron ya quedo en la 0010.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0011"
down_revision: str | None = "0010"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema: `last_reminder_days` -> `last_reminder_slot`."""
    op.add_column(
        "recurring_occurrences",
        sa.Column("last_reminder_slot", sa.SmallInteger(), nullable=True),
    )
    op.execute(
        "UPDATE recurring_occurrences SET last_reminder_slot = CASE last_reminder_days "
        "WHEN 7 THEN 1 WHEN 2 THEN 2 WHEN 1 THEN 3 END "
        "WHERE last_reminder_days IS NOT NULL"
    )
    op.create_check_constraint(
        op.f("ck_recurring_occurrences_last_reminder_slot_valido"),
        "recurring_occurrences",
        "last_reminder_slot IS NULL OR last_reminder_slot BETWEEN 1 AND 4",
    )
    op.drop_constraint(
        op.f("ck_recurring_occurrences_last_reminder_days_valido"),
        "recurring_occurrences",
        type_="check",
    )
    op.drop_column("recurring_occurrences", "last_reminder_days")


def downgrade() -> None:
    """Downgrade schema: vuelve a `last_reminder_days` (el aviso de las 17 cuenta como 1)."""
    op.add_column(
        "recurring_occurrences",
        sa.Column("last_reminder_days", sa.SmallInteger(), nullable=True),
    )
    op.execute(
        "UPDATE recurring_occurrences SET last_reminder_days = CASE last_reminder_slot "
        "WHEN 1 THEN 7 WHEN 2 THEN 2 ELSE 1 END "
        "WHERE last_reminder_slot IS NOT NULL"
    )
    op.create_check_constraint(
        op.f("ck_recurring_occurrences_last_reminder_days_valido"),
        "recurring_occurrences",
        "last_reminder_days IS NULL OR last_reminder_days IN (1, 2, 7)",
    )
    op.drop_constraint(
        op.f("ck_recurring_occurrences_last_reminder_slot_valido"),
        "recurring_occurrences",
        type_="check",
    )
    op.drop_column("recurring_occurrences", "last_reminder_slot")
