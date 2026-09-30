"""DTOs de los casos de uso de recurring (frozen, stdlib puro)."""

from __future__ import annotations

import enum
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from uuid import UUID

from luka.modules.recurring.domain.entities import (
    DEFAULT_REMIND_DAYS_BEFORE,
    DEFAULT_TOLERANCE_PCT,
    Occurrence,
    RecurringExpense,
)


class _Unset(enum.Enum):
    """Sentinel de PATCH parcial ("no enviado", distinto de `None`)."""

    UNSET = enum.auto()

    def __repr__(self) -> str:
        return "UNSET"

    def __bool__(self) -> bool:
        return False


Unset = _Unset
UNSET = _Unset.UNSET


@dataclass(frozen=True, slots=True)
class ExpenseInput:
    """Body de `POST /recurring-expenses` ya validado en forma (spec 005 SS10)."""

    name: str
    merchant_keyword: str
    expected_amount: Decimal
    day_of_month: int
    amount_tolerance_pct: int = DEFAULT_TOLERANCE_PCT
    remind_days_before: int = DEFAULT_REMIND_DAYS_BEFORE
    category_id: UUID | None = None
    account_id: UUID | None = None


@dataclass(frozen=True, slots=True)
class ExpensePatch:
    """Campos de `PATCH /recurring-expenses/{id}`; `UNSET` = no enviado."""

    name: str | Unset = UNSET
    merchant_keyword: str | Unset = UNSET
    expected_amount: Decimal | Unset = UNSET
    day_of_month: int | Unset = UNSET
    amount_tolerance_pct: int | Unset = UNSET
    remind_days_before: int | Unset = UNSET
    category_id: UUID | Unset | None = UNSET
    account_id: UUID | Unset | None = UNSET
    active: bool | Unset = UNSET


@dataclass(frozen=True, slots=True)
class TransactionSummary:
    """Resumen de la transaccion que pago una ocurrencia (spec 005 SS10)."""

    id: UUID
    merchant: str | None
    amount: Decimal
    occurred_at: datetime


@dataclass(frozen=True, slots=True)
class OccurrenceView:
    """Ocurrencia con su gasto fijo y, si esta pagada, su transaccion."""

    occurrence: Occurrence
    expense: RecurringExpense
    transaction: TransactionSummary | None


@dataclass(frozen=True, slots=True)
class DueReminder:
    """Recordatorio que toca enviar hoy (spec 011 SS5)."""

    occurrence_id: UUID
    user_id: UUID
    name: str
    expected_amount: Decimal
    due_date_iso: str
    remind_days_before: int
