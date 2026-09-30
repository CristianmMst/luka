"""Handlers de recurring para eventos del ledger (spec 011 SS4, spec 003 SS2.3).

Se tipa directo contra `ledger.events` (entrada explicita en R4:
`recurring.infrastructure.consumers -> ledger.events`), igual que ledger con
`parsing.events`. Cada evento abre su propia sesion; el matcher es idempotente
(`UPDATE ... WHERE status = 'pending'` + indice unico), asi que una reentrega no
empareja dos veces (P2).
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import structlog

from luka.modules.ledger.events import TransactionCaptured, TransactionDeleted
from luka.modules.recurring.application.use_cases.background import (
    MatchCapturedTransaction,
    RevertDeletedTransaction,
)
from luka.modules.recurring.domain.matcher import TxCandidate
from luka.modules.recurring.infrastructure.repositories import (
    SqlAlchemyOccurrenceRepository,
    SqlAlchemyRejectionRepository,
)
from luka.modules.recurring.infrastructure.uow import SqlAlchemyUnitOfWork

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

    from luka.modules.recurring.application.ports import ClockPort
    from luka.shared.events.port import EventHandler

_logger = structlog.get_logger()


def make_transaction_captured_handler(
    *, session_factory: async_sessionmaker[AsyncSession], clock: ClockPort
) -> EventHandler:
    """`EventHandler` del grupo `recurring` de `ledger.TransactionCaptured` (AC-12.2)."""

    async def handler(event: object) -> None:
        if not isinstance(event, TransactionCaptured):
            _logger.warning(
                "recurring_consumer_invalid_event",
                handler="transaction_captured",
                event_type=type(event).__name__,
            )
            return
        tx = TxCandidate(
            id=event.transaction_id,
            amount=event.amount,
            merchant=event.merchant,
            account_id=event.account_id,
            occurred_at=event.transaction_occurred_at,
            # `Kind`/`Direction` son StrEnum de ledger.domain (R4 no deja importarlos):
            # se comparan por valor.
            is_expense_debit=event.kind == "expense" and event.direction == "debit",
        )
        if not tx.is_expense_debit:
            return
        async with session_factory() as session:
            use_case = MatchCapturedTransaction(
                occurrences=SqlAlchemyOccurrenceRepository(session),
                rejections=SqlAlchemyRejectionRepository(session),
                clock=clock,
                uow=SqlAlchemyUnitOfWork(session),
            )
            matched = await use_case.execute(event.user_id, tx)
        # Solo el resultado: nunca comercio, monto ni nombre del gasto fijo (P1).
        _logger.info("recurring_payment_matched", matched=matched is not None)

    return handler


def make_transaction_deleted_handler(
    *, session_factory: async_sessionmaker[AsyncSession]
) -> EventHandler:
    """`EventHandler` del grupo `recurring` de `ledger.TransactionDeleted`."""

    async def handler(event: object) -> None:
        if not isinstance(event, TransactionDeleted):
            _logger.warning(
                "recurring_consumer_invalid_event",
                handler="transaction_deleted",
                event_type=type(event).__name__,
            )
            return
        async with session_factory() as session:
            use_case = RevertDeletedTransaction(
                occurrences=SqlAlchemyOccurrenceRepository(session),
                uow=SqlAlchemyUnitOfWork(session),
            )
            reverted = await use_case.execute(event.user_id, event.transaction_id)
        _logger.info("recurring_payment_released", reverted=reverted)

    return handler


__all__ = ["make_transaction_captured_handler", "make_transaction_deleted_handler"]
