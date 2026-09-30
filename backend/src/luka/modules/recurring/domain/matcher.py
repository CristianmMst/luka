"""Matcher de pagos de gastos fijos (spec 011 SS4). Logica pura, solo stdlib (P3)."""

from __future__ import annotations

from collections.abc import Collection, Sequence
from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from luka.modules.recurring.domain.entities import Occurrence, RecurringExpense, normalize_text
from luka.modules.recurring.domain.enums import OccurrenceStatus
from luka.modules.recurring.domain.schedule import colombia_date, window


@dataclass(frozen=True, slots=True)
class TxCandidate:
    """Lo que el matcher necesita de una transaccion del ledger."""

    id: UUID
    amount: Decimal
    merchant: str | None
    account_id: UUID | None
    occurred_at: datetime
    is_expense_debit: bool

    @property
    def local_date(self) -> date:
        return colombia_date(self.occurred_at)


def within_tolerance(amount: Decimal, expected: Decimal, tolerance_pct: int) -> bool:
    """`|amount - expected| <= expected * tolerance_pct / 100`; el borde cuenta."""
    return abs(amount - expected) * 100 <= expected * tolerance_pct


def matches(tx: TxCandidate, occurrence: Occurrence, expense: RecurringExpense) -> bool:
    """Reglas 1-6 de spec 011 SS4 para un par (transaccion, ocurrencia)."""
    if not tx.is_expense_debit or not expense.active:
        return False
    if occurrence.status is not OccurrenceStatus.PENDING:
        return False
    merchant = normalize_text(tx.merchant or "")
    tokens = expense.keyword_tokens
    # Basta una palabra del nombre en el comercio: "Spotify Familiar" -> SPOTIFY P3A9C1.
    if not merchant or not any(token in merchant for token in tokens):
        return False
    if not within_tolerance(tx.amount, expense.expected_amount, expense.amount_tolerance_pct):
        return False
    start, end = window(occurrence.due_date)
    if not start <= tx.local_date <= end:
        return False
    return expense.account_id is None or expense.account_id == tx.account_id


def pick_occurrence(
    tx: TxCandidate,
    candidates: Sequence[tuple[Occurrence, RecurringExpense]],
    rejected: Collection[UUID],
) -> Occurrence | None:
    """Ocurrencia que paga `tx`, o `None` si ninguna aplica o hay empate (regla 7).

    `rejected` son las ocurrencias que el usuario ya desemparejo de `tx`.
    Desempate: monto mas cercano al esperado y, luego, `due_date` mas cercano.
    """
    scored: list[tuple[Decimal, int, Occurrence]] = []
    for occurrence, expense in candidates:
        if occurrence.id in rejected or not matches(tx, occurrence, expense):
            continue
        amount_gap = abs(tx.amount - expense.expected_amount)
        day_gap = abs((tx.local_date - occurrence.due_date).days)
        scored.append((amount_gap, day_gap, occurrence))
    if not scored:
        return None
    scored.sort(key=lambda item: (item[0], item[1]))
    best = scored[0]
    if len(scored) > 1 and scored[1][:2] == best[:2]:
        return None
    return best[2]


def reminder_due(occurrence: Occurrence, expense: RecurringExpense, today: date) -> bool:
    """El aviso toca desde `due - remind_days_before` hasta `due`, una sola vez (spec 011 SS5)."""
    if occurrence.status is not OccurrenceStatus.PENDING or occurrence.reminded_at is not None:
        return False
    if not expense.active:
        return False
    first_day = occurrence.due_date.toordinal() - expense.remind_days_before
    return first_day <= today.toordinal() <= occurrence.due_date.toordinal()
