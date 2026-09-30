"""Fabrica del handler de `ingestion.RawMessageReceived` (D7): finas fabricas
en `infrastructure/consumers.py`, el worker (composition root) solo cablea.

`raw_message_id` se lee por duck typing (`event.raw_message_id`) en vez de
tipar `event` contra `ingestion.events.RawMessageReceived`: eso evitaria un
import de `parsing.infrastructure` a `ingestion.events` (un cruce nuevo que
requeriria otra entrada `ignore_imports` en R4 sin necesidad real, ya que el
`EventRegistry` decodifica el evento correcto para el `event_type` suscrito).
"""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import UUID

import structlog

from luka.modules.parsing.application.use_cases.parse_raw_message import ParseRawMessage
from luka.modules.parsing.infrastructure.event_publisher import BusEventPublisher
from luka.modules.parsing.infrastructure.raw_message_gateway import IngestionRawMessageGateway
from luka.modules.parsing.infrastructure.uow import SqlAlchemyUnitOfWork

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

    from luka.modules.parsing.application.ports import (
        ClockPort,
        LlmBudgetPort,
        LlmParserPort,
        MetricsPort,
        TemplateRegistryPort,
    )
    from luka.shared.events.port import EventBusPort, EventHandler
    from luka.shared.settings import Settings

_logger = structlog.get_logger()


def make_raw_message_received_handler(  # noqa: PLR0913 - un parametro por dependencia externa
    *,
    session_factory: async_sessionmaker[AsyncSession],
    event_bus: EventBusPort,
    clock: ClockPort,
    llm: LlmParserPort,
    budget: LlmBudgetPort,
    registry: TemplateRegistryPort,
    known_banks: frozenset[str],
    metrics: MetricsPort,
    settings: Settings,
) -> EventHandler:
    """`EventHandler` para el grupo `parsing` de `ingestion.RawMessageReceived`.

    `known_banks` son los bancos validos en la salida del LLM: el allowlist de
    remitentes (`ParsingConfig.senders.known_banks()`, 6 bancos), NO los bancos
    con plantilla (`registry.known_banks()`, hoy solo `bancolombia`); ver el
    docstring de `ParseRawMessage.__init__`.

    Cada evento abre su propia `AsyncSession` (una transaccion por mensaje).
    Excepciones inesperadas de `ParseRawMessage.execute` (p. ej. el publish al
    bus, ver `BusEventPublisher`) se dejan propagar: `StreamConsumer` deja el
    mensaje pendiente (PEL) y lo reintenta, hasta DLQ tras `max_deliveries`.
    """

    async def handler(event: object) -> None:
        raw_message_id = getattr(event, "raw_message_id", None)
        if not isinstance(raw_message_id, UUID):
            _logger.warning("parsing_consumer_invalid_event", event_type=type(event).__name__)
            return

        async with session_factory() as session:
            use_case = ParseRawMessage(
                gateway=IngestionRawMessageGateway(session),
                llm=llm,
                budget=budget,
                registry=registry,
                metrics=metrics,
                events=BusEventPublisher(event_bus),
                clock=clock,
                uow=SqlAlchemyUnitOfWork(session),
                known_banks=known_banks,
                llm_budget_limit=settings.llm_monthly_token_budget_per_user,
                confidence_threshold=settings.llm_confidence_threshold,
            )
            result = await use_case.execute(raw_message_id)

        _logger.info(
            "parsing_outcome",
            outcome=type(result).__name__,
            raw_message_id=str(raw_message_id),
        )

    return handler


__all__ = ["make_raw_message_received_handler"]
