"""Modelos ORM de recurring: gastos fijos, ocurrencias y rechazos (spec 004 SS2.12-2.14).

`transaction_id` es una referencia entre modulos sin FK: si la tuviera con `SET
NULL`, al borrar la transaccion el consumer de `ledger.TransactionDeleted` ya no
podria encontrar la ocurrencia que pagaba para devolverla a `pending` (spec 011
SS4). `category_id`/`account_id` si llevan FK `SET NULL`: borrar la categoria o la
cuenta solo le quita el icono o el filtro al gasto fijo.
"""

import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    PrimaryKeyConstraint,
    SmallInteger,
    Text,
    UniqueConstraint,
    Uuid,
    func,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from luka.shared.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

_STATUS_VALUES = "'pending','paid','skipped'"
_MATCHED_BY_VALUES = "'auto','manual'"


class RecurringExpenseRow(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Tabla `recurring_expenses` (spec 004 SS2.12)."""

    __tablename__ = "recurring_expenses"
    __table_args__ = (
        CheckConstraint("expected_amount > 0", name="expected_amount_positivo"),
        CheckConstraint("amount_tolerance_pct BETWEEN 0 AND 50", name="amount_tolerance_pct_rango"),
        CheckConstraint("day_of_month BETWEEN 1 AND 31", name="day_of_month_rango"),
        CheckConstraint("remind_days_before IN (1, 2)", name="remind_days_before_valido"),
        Index(None, "user_id", "active"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    merchant_keyword: Mapped[str] = mapped_column(Text, nullable=False)
    expected_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    amount_tolerance_pct: Mapped[int] = mapped_column(
        SmallInteger, nullable=False, server_default=text("10")
    )
    day_of_month: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    category_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"), nullable=True
    )
    account_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("linked_accounts.id", ondelete="SET NULL"), nullable=True
    )
    remind_days_before: Mapped[int] = mapped_column(
        SmallInteger, nullable=False, server_default=text("1")
    )
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))


class RecurringOccurrenceRow(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Tabla `recurring_occurrences`: un gasto fijo en un mes (spec 004 SS2.13)."""

    __tablename__ = "recurring_occurrences"
    __table_args__ = (
        CheckConstraint(f"status IN ({_STATUS_VALUES})", name="status_valido"),
        CheckConstraint(
            f"matched_by IS NULL OR matched_by IN ({_MATCHED_BY_VALUES})",
            name="matched_by_valido",
        ),
        CheckConstraint(
            "(status = 'paid') = (matched_by IS NOT NULL AND paid_at IS NOT NULL)",
            name="pago_consistente",
        ),
        CheckConstraint(
            "transaction_id IS NULL OR status = 'paid'", name="transaccion_solo_si_pagada"
        ),
        UniqueConstraint("recurring_expense_id", "period"),
        Index(
            "uq_recurring_occurrences_transaction_id",
            "transaction_id",
            unique=True,
            postgresql_where=text("transaction_id IS NOT NULL"),
        ),
        Index(None, "user_id", "period"),
        Index(None, "user_id", "updated_at", "id"),
        CheckConstraint(
            "last_reminder_days IS NULL OR last_reminder_days IN (1, 2, 7)",
            name="last_reminder_days_valido",
        ),
        Index(
            "ix_recurring_occurrences_due_date_pendientes",
            "due_date",
            postgresql_where=text("status = 'pending'"),
        ),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    recurring_expense_id: Mapped[uuid.UUID] = mapped_column(
        # Nombre explicito: el de la convencion pasa de 63 caracteres (limite de Postgres).
        ForeignKey(
            "recurring_expenses.id",
            ondelete="CASCADE",
            name="fk_recurring_occurrences_expense_id",
        ),
        nullable=False,
    )
    period: Mapped[date] = mapped_column(Date, nullable=False)
    due_date: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'pending'"))
    transaction_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(as_uuid=True), nullable=True)
    matched_by: Mapped[str | None] = mapped_column(Text, nullable=True)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    reminded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_reminder_days: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)


class RecurringMatchRejectionRow(Base):
    """Tabla `recurring_match_rejections`: pares desemparejados (spec 004 SS2.14)."""

    __tablename__ = "recurring_match_rejections"
    __table_args__ = (PrimaryKeyConstraint("occurrence_id", "transaction_id"),)

    occurrence_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey(
            "recurring_occurrences.id",
            ondelete="CASCADE",
            name="fk_recurring_match_rejections_occurrence_id",
        ),
        nullable=False,
    )
    transaction_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
