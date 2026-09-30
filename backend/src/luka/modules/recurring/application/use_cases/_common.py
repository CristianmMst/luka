"""Piezas compartidas por los casos de uso de recurring (spec 011 SS3-SS4)."""

from __future__ import annotations

from datetime import UTC, date, datetime, time, timedelta
from uuid import UUID

from luka.modules.recurring.application.ports import (
    ClockPort,
    IdGeneratorPort,
    LedgerPort,
    OccurrenceRepositoryPort,
    RejectionRepositoryPort,
)
from luka.modules.recurring.domain.entities import Occurrence, RecurringExpense
from luka.modules.recurring.domain.enums import OccurrenceStatus
from luka.modules.recurring.domain.errors import OccurrenceNotFound
from luka.modules.recurring.domain.matcher import TxCandidate, pick_occurrence
from luka.modules.recurring.domain.schedule import (
    BOGOTA,
    DETECTION_WINDOW_DAYS,
    colombia_date,
    due_date,
    periods_to_ensure,
    window,
)


def today_in_colombia(clock: ClockPort) -> date:
    """Fecha local de Colombia segun el reloj inyectado."""
    return colombia_date(clock.now())


def new_occurrence(ids: IdGeneratorPort, expense: RecurringExpense, period: date) -> Occurrence:
    return Occurrence(
        id=ids.new_id(),
        user_id=expense.user_id,
        recurring_expense_id=expense.id,
        period=period,
        due_date=due_date(period, expense.day_of_month),
        status=OccurrenceStatus.PENDING,
        transaction_id=None,
        matched_by=None,
        paid_at=None,
        reminded_at=None,
    )


async def ensure_occurrences(
    occurrences: OccurrenceRepositoryPort,
    ids: IdGeneratorPort,
    expense: RecurringExpense,
    *,
    today: date,
    since: date,
) -> int:
    """Crea (idempotente) la ocurrencia del mes actual y la del siguiente."""
    created = 0
    for period in periods_to_ensure(today, since, expense.day_of_month):
        if await occurrences.add_if_absent(new_occurrence(ids, expense, period)):
            created += 1
    return created


async def get_owned_occurrence(
    occurrences: OccurrenceRepositoryPort, user_id: UUID, id: UUID
) -> Occurrence:
    occurrence = await occurrences.get(user_id, id)
    if occurrence is None:
        raise OccurrenceNotFound
    return occurrence


async def match_transaction(
    *,
    occurrences: OccurrenceRepositoryPort,
    rejections: RejectionRepositoryPort,
    clock: ClockPort,
    user_id: UUID,
    tx: TxCandidate,
) -> UUID | None:
    """Empareja `tx` con la ocurrencia que paga, si hay una sola (spec 011 SS4).

    No hace commit: lo decide el llamador. Devuelve el id emparejado o `None`.
    """
    if not tx.is_expense_debit:
        return None
    local = tx.local_date
    delta = timedelta(days=DETECTION_WINDOW_DAYS)
    candidates = await occurrences.candidates(user_id, local - delta, local + delta)
    if not candidates:
        return None
    rejected = await rejections.rejected_occurrences(tx.id, [occ.id for occ, _ in candidates])
    chosen = pick_occurrence(tx, candidates, rejected)
    if chosen is None:
        return None
    if await occurrences.claim_auto(chosen.id, tx.id, clock.now()):
        return chosen.id
    return None


def _day_bounds(start: date, end: date) -> tuple[datetime, datetime]:
    """Instantes UTC que cubren de las 00:00 de `start` a las 24:00 de `end` en Colombia."""
    begin = datetime.combine(start, time.min, tzinfo=BOGOTA).astimezone(UTC)
    finish = datetime.combine(end + timedelta(days=1), time.min, tzinfo=BOGOTA).astimezone(UTC)
    return begin, finish


async def sweep_expense(
    *,
    occurrences: OccurrenceRepositoryPort,
    rejections: RejectionRepositoryPort,
    ledger: LedgerPort,
    clock: ClockPort,
    expense: RecurringExpense,
) -> int:
    """Barrido retroactivo: aplica el matcher a los gastos ya capturados en la ventana
    de cada ocurrencia `pending` del gasto fijo (spec 011 SS4, AC-12.3)."""
    if not expense.active:
        return 0
    matched = 0
    for occurrence in await occurrences.pending_for_expense(expense.id):
        start, end = window(occurrence.due_date)
        begin, finish = _day_bounds(start, end)
        txs = await ledger.expenses_in_window(expense.user_id, begin, finish)
        for tx in sorted(txs, key=lambda item: item.occurred_at):
            if await match_transaction(
                occurrences=occurrences,
                rejections=rejections,
                clock=clock,
                user_id=expense.user_id,
                tx=tx,
            ):
                matched += 1
    return matched
