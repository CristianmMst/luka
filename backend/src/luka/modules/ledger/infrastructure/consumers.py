"""Fabricas de los handlers de `parsing.TransactionParsed`/`parsing.ParseFailed` (D7).

Fabricas finas: el worker (composition root) solo cablea. A diferencia del
consumer de parsing (que lee el evento por duck typing para no cruzar a
`ingestion.events`), aqui se tipa directamente contra `parsing.events`
(`TransactionParsed`/`ParseFailed`): es el cruce explicito que documenta el
controller ruling D7 y que agrega la entrada nueva en R4
(`luka.modules.ledger.infrastructure.consumers -> luka.modules.parsing.events`).

Cada evento abre su propia `AsyncSession` (una transaccion por mensaje), igual que
`parsing/infrastructure/consumers.py`.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import structlog

from luka.modules.ledger import public as ledger_public
from luka.modules.ledger.application.dto import (
    CapturedTransactionCommand,
    EnqueueForReviewCommand,
    SourceInput,
)
from luka.modules.ledger.application.use_cases.enqueue_for_review import EnqueueForReview
from luka.modules.ledger.domain.enums import Bank, Channel, Direction
from luka.modules.ledger.domain.errors import CaptureAlreadyResolved
from luka.modules.ledger.domain.review import ReviewReason
from luka.modules.ledger.infrastructure.repositories.review_queue import (
    SqlAlchemyReviewQueueRepository,
)
from luka.modules.ledger.infrastructure.uow import SqlAlchemyUnitOfWork
from luka.modules.parsing.events import ParseFailed, TransactionParsed

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

    from luka.modules.ledger.application.ports import ClockPort
    from luka.shared.events.port import EventBusPort, EventHandler

_logger = structlog.get_logger()


def _bank(value: str) -> Bank:
    """`Bank(event.bank)` con fallback `Bank.OTHER` (D4)."""
    try:
        return Bank(value)
    except ValueError:
        return Bank.OTHER


def make_transaction_parsed_handler(
    *,
    session_factory: async_sessionmaker[AsyncSession],
    event_bus: EventBusPort,
    clock: ClockPort,
) -> EventHandler:
    """`EventHandler` para el grupo `ledger` de `parsing.TransactionParsed` (F2.6)."""

    async def handler(event: object) -> None:
        if not isinstance(event, TransactionParsed):
            _logger.warning(
                "ledger_consumer_invalid_event",
                handler="transaction_parsed",
                event_type=type(event).__name__,
            )
            return

        bank = _bank(event.bank)
        cmd = CapturedTransactionCommand(
            user_id=event.user_id,
            bank=bank,
            amount=event.amount,
            direction=Direction(event.direction.value),
            occurred_at=event.transaction_occurred_at,
            last4=event.last4,
            merchant=event.merchant,
            description=None,
            suggested_category_slug=event.suggested_category,
            parsed_by=event.parsed_by,
            confidence=event.confidence,
            source=SourceInput(
                channel=Channel(event.channel),
                raw_message_id=event.raw_message_id,
                received_at=event.received_at,
            ),
            merchant_is_person=event.merchant_is_person,
        )

        try:
            async with session_factory() as session:
                recorded = await ledger_public.record_captured_transaction(
                    session, event_bus, clock, cmd
                )
        except CaptureAlreadyResolved:
            # Carrera reparse vs. convert/discard (spec 006 SS4.4): el usuario ya
            # resolvio el item; el evento queda atendido (sin reintento). Sin ids,
            # montos ni comercio (P1).
            _logger.info(
                "ledger_capture_skipped",
                reason="review_already_resolved",
                bank=bank.value,
                channel=event.channel,
            )
            return

        if not recorded.created:
            _logger.info(
                "parsing_metric",
                outcome="dedupe_hit",
                bank=bank.value,
                channel=event.channel,
            )

    return handler


def make_parse_failed_handler(
    *, session_factory: async_sessionmaker[AsyncSession], clock: ClockPort
) -> EventHandler:
    """`EventHandler` para el grupo `ledger-review` de `parsing.ParseFailed` (F2.6)."""

    async def handler(event: object) -> None:
        if not isinstance(event, ParseFailed):
            _logger.warning(
                "ledger_consumer_invalid_event",
                handler="parse_failed",
                event_type=type(event).__name__,
            )
            return

        cmd = EnqueueForReviewCommand(
            raw_message_id=event.raw_message_id,
            user_id=event.user_id,
            reason=ReviewReason(event.reason.value),
            partial_extract=dict(event.partial_extract),
        )

        async with session_factory() as session:
            use_case = EnqueueForReview(
                review_queue=SqlAlchemyReviewQueueRepository(session),
                clock=clock,
                uow=SqlAlchemyUnitOfWork(session),
            )
            await use_case.execute(cmd)

    return handler


__all__ = ["make_parse_failed_handler", "make_transaction_parsed_handler"]
