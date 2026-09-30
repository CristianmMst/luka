"""Matcher de pagos de gastos fijos (spec 011 SS4). Logica pura, solo stdlib (P3)."""

from __future__ import annotations

from collections.abc import Collection, Sequence
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from decimal import Decimal
from uuid import UUID

from luka.modules.recurring.domain.entities import Occurrence, RecurringExpense, normalize_text
from luka.modules.recurring.domain.enums import OccurrenceStatus
from luka.modules.recurring.domain.schedule import BOGOTA, colombia_date, window


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


#: Avisos de cada gasto fijo (spec 011 SS5): (dias antes, hora en Colombia). El numero
#: de aviso (1-4) es su posicion: 7 dias a las 9, 2 dias a las 9 y el dia antes a las 9
#: y a las 17.
REMINDER_SLOTS = ((7, 9), (2, 9), (1, 9), (1, 17))
REMINDER_HORIZON_DAYS = max(days for days, _ in REMINDER_SLOTS)


def reminder_fire_at(due: date, slot: int) -> datetime:
    """Instante (hora de Colombia) del aviso `slot` de un pago que vence `due`."""
    days, hour = REMINDER_SLOTS[slot - 1]
    day = due - timedelta(days=days)
    return datetime(day.year, day.month, day.day, hour, tzinfo=BOGOTA)


def reminder_slot_due(
    occurrence: Occurrence, expense: RecurringExpense, now: datetime
) -> int | None:
    """El aviso (1-4) que toca enviar ahora, o `None` (spec 011 SS5).

    Toca el mas reciente cuya hora ya paso, si es posterior al ultimo enviado: cada
    aviso sale a lo sumo una vez y, si el cron no corrio, no se mandan de golpe los
    atrasados, solo el ultimo. Nunca se avisa de un pago ya vencido.
    """
    if occurrence.status is not OccurrenceStatus.PENDING or not expense.active:
        return None
    if colombia_date(now) > occurrence.due_date:
        return None
    fired = [
        slot
        for slot in range(1, len(REMINDER_SLOTS) + 1)
        if reminder_fire_at(occurrence.due_date, slot) <= now
    ]
    if not fired:
        return None
    slot = max(fired)
    last = occurrence.last_reminder_slot
    if last is not None and slot <= last:
        return None
    return slot
