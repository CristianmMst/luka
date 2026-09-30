"""recurring_expenses

Revision ID: 0008
Revises: 0007
Create Date: 2026-09-30 10:00:00.000000

Gastos fijos (RF-12, spec 004 SS2.12-2.14): `recurring_expenses`, sus ocurrencias
mensuales y los emparejamientos que el usuario deshizo. `transaction_id` no lleva
FK a `transactions`: el consumer de `ledger.TransactionDeleted` necesita encontrar
la ocurrencia por ese id despues del borrado (spec 011 SS4).
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0008"
down_revision: str | None = "0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_STATUS_VALUES = "'pending','paid','skipped'"
_MATCHED_BY_VALUES = "'auto','manual'"


def _timestamps() -> list[sa.Column[object]]:
    return [
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    ]


def upgrade() -> None:
    """Upgrade schema: crea las tablas de gastos fijos."""
    op.create_table(
        "recurring_expenses",
        sa.Column("id", sa.Uuid(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("merchant_keyword", sa.Text(), nullable=False),
        sa.Column("expected_amount", sa.Numeric(14, 2), nullable=False),
        sa.Column(
            "amount_tolerance_pct", sa.SmallInteger(), server_default=sa.text("10"), nullable=False
        ),
        sa.Column("day_of_month", sa.SmallInteger(), nullable=False),
        sa.Column("category_id", sa.Uuid(), nullable=True),
        sa.Column("account_id", sa.Uuid(), nullable=True),
        sa.Column(
            "remind_days_before", sa.SmallInteger(), server_default=sa.text("1"), nullable=False
        ),
        sa.Column("active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        *_timestamps(),
        sa.CheckConstraint("expected_amount > 0", name="expected_amount_positivo"),
        sa.CheckConstraint(
            "amount_tolerance_pct BETWEEN 0 AND 50", name="amount_tolerance_pct_rango"
        ),
        sa.CheckConstraint("day_of_month BETWEEN 1 AND 31", name="day_of_month_rango"),
        sa.CheckConstraint("remind_days_before IN (1, 2)", name="remind_days_before_valido"),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_recurring_expenses_user_id_users",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["category_id"],
            ["categories.id"],
            name="fk_recurring_expenses_category_id_categories",
            ondelete="SET NULL",
        ),
        sa.ForeignKeyConstraint(
            ["account_id"],
            ["linked_accounts.id"],
            name="fk_recurring_expenses_account_id_linked_accounts",
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_recurring_expenses"),
    )
    op.create_index(
        "ix_recurring_expenses_user_id_active", "recurring_expenses", ["user_id", "active"]
    )

    op.create_table(
        "recurring_occurrences",
        sa.Column("id", sa.Uuid(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("recurring_expense_id", sa.Uuid(), nullable=False),
        sa.Column("period", sa.Date(), nullable=False),
        sa.Column("due_date", sa.Date(), nullable=False),
        sa.Column("status", sa.Text(), server_default=sa.text("'pending'"), nullable=False),
        sa.Column("transaction_id", sa.Uuid(), nullable=True),
        sa.Column("matched_by", sa.Text(), nullable=True),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("reminded_at", sa.DateTime(timezone=True), nullable=True),
        *_timestamps(),
        sa.CheckConstraint(f"status IN ({_STATUS_VALUES})", name="status_valido"),
        sa.CheckConstraint(
            f"matched_by IS NULL OR matched_by IN ({_MATCHED_BY_VALUES})",
            name="matched_by_valido",
        ),
        sa.CheckConstraint(
            "(status = 'paid') = (matched_by IS NOT NULL AND paid_at IS NOT NULL)",
            name="pago_consistente",
        ),
        sa.CheckConstraint(
            "transaction_id IS NULL OR status = 'paid'", name="transaccion_solo_si_pagada"
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_recurring_occurrences_user_id_users",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["recurring_expense_id"],
            ["recurring_expenses.id"],
            # Nombre corto: el de la convencion pasa de 63 caracteres.
            name="fk_recurring_occurrences_expense_id",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_recurring_occurrences"),
        sa.UniqueConstraint(
            "recurring_expense_id",
            "period",
            name="uq_recurring_occurrences_recurring_expense_id_period",
        ),
    )
    op.create_index(
        "uq_recurring_occurrences_transaction_id",
        "recurring_occurrences",
        ["transaction_id"],
        unique=True,
        postgresql_where=sa.text("transaction_id IS NOT NULL"),
    )
    op.create_index(
        "ix_recurring_occurrences_user_id_period", "recurring_occurrences", ["user_id", "period"]
    )
    op.create_index(
        "ix_recurring_occurrences_user_id_updated_at_id",
        "recurring_occurrences",
        ["user_id", "updated_at", "id"],
    )
    op.create_index(
        "ix_recurring_occurrences_due_date_pendientes",
        "recurring_occurrences",
        ["due_date"],
        postgresql_where=sa.text("status = 'pending' AND reminded_at IS NULL"),
    )

    op.create_table(
        "recurring_match_rejections",
        sa.Column("occurrence_id", sa.Uuid(), nullable=False),
        sa.Column("transaction_id", sa.Uuid(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["occurrence_id"],
            ["recurring_occurrences.id"],
            name="fk_recurring_match_rejections_occurrence_id",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint(
            "occurrence_id", "transaction_id", name="pk_recurring_match_rejections"
        ),
    )


def downgrade() -> None:
    """Downgrade schema: dropea las tablas de gastos fijos."""
    op.drop_table("recurring_match_rejections")
    op.drop_index(
        "ix_recurring_occurrences_due_date_pendientes", table_name="recurring_occurrences"
    )
    op.drop_index(
        "ix_recurring_occurrences_user_id_updated_at_id", table_name="recurring_occurrences"
    )
    op.drop_index("ix_recurring_occurrences_user_id_period", table_name="recurring_occurrences")
    op.drop_index("uq_recurring_occurrences_transaction_id", table_name="recurring_occurrences")
    op.drop_table("recurring_occurrences")
    op.drop_index("ix_recurring_expenses_user_id_active", table_name="recurring_expenses")
    op.drop_table("recurring_expenses")
