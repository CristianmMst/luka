"""Test e2e de higiene de metricas (spec 006 SS6, P1/P6, F2.2/F2.5/F2.6):
`parsing_metric` nunca lleva el monto/comercio, y sus claves son un conjunto
cerrado.
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest
import structlog.testing
from support.clock import FixedClock
from support.email_fixtures import bancolombia_fixtures
from support.pipeline import (
    InMemoryBudget,
    PipelineHarness,
    count_transactions,
    pipeline_drained,
    review_reason,
)
from support.raw_messages import insert_raw_message

from finanzia.modules.ingestion.application.dto import RawMessageInput
from finanzia.modules.ingestion.domain.enums import Channel
from finanzia.modules.ingestion.events import RawMessageReceived
from finanzia.modules.ingestion.public import Accepted, ingest_raw_message
from finanzia.modules.parsing.infrastructure.llm.disabled import DisabledLlmParser
from finanzia.shared.clock import SystemClock

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable

    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
    from support.auth import AuthedUser

    from finanzia.shared.events.codec import EventRegistry
    from finanzia.shared.events.redis_streams import RedisStreamsEventBus
    from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration

_COMPRA_TDEB = next(f for f in bancolombia_fixtures() if f.name == "compra_tdeb.txt")
_AMOUNT = "176824"  # el monto de `compra_tdeb.txt`, sin separadores (spec 006 SS6)
_MERCHANT = "CARBON Y XILVESTRE T"

_ALLOWED_OUTCOMES = {
    "accepted",
    "duplicate",
    "discarded",
    "parsed_by_rule",
    "parsed_by_llm",
    "sent_to_review",
    "dedupe_hit",
}
_ALLOWED_KEYS = {
    "outcome",
    "bank",
    "channel",
    "template_id",
    "reason",
    "llm_tokens",
    "republished",
    "event",
    "level",
    "timestamp",
    "log_level",
    "logger",
}

# Excerpt sin plantilla y con LLM deshabilitado: siempre termina en revision
# (`sent_to_review`, D12: `reason=llm_disabled`), sin monto/comercio real de por medio.
_NO_TEMPLATE_BODY = "Bancolombia: Retiraste $50.000 en cajero El Poblado el 01/01/2026 a las 10:00."
_NO_TEMPLATE_RECEIVED_AT = datetime(2026, 1, 1, 15, 0, tzinfo=UTC)


async def test_parsing_metric_no_filtra_datos_y_tiene_claves_cerradas(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    clock = FixedClock(_COMPRA_TDEB.received_at)

    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=clock,
        llm=DisabledLlmParser(),
        budget=InMemoryBudget(),
        settings=settings,
    )
    try:
        with structlog.testing.capture_logs() as captured:
            # 1) parseo por regla (outcome=parsed_by_rule).
            async with session_factory() as session:
                outcome = await ingest_raw_message(
                    session,
                    bus,
                    clock,
                    RawMessageInput(
                        user_id=user.id,
                        channel=Channel.EMAIL,
                        external_id=_COMPRA_TDEB.name,
                        sender=_COMPRA_TDEB.sender,
                        title=None,
                        text=_COMPRA_TDEB.body,
                        received_at=_COMPRA_TDEB.received_at,
                    ),
                )
            assert isinstance(outcome, Accepted)

            async def has_one_transaction() -> bool:
                return await count_transactions(session_factory, user.id) == 1

            assert await harness.wait_for(has_one_transaction)

            # 2) reentrega manual (misma fila, ya `parsed`) -> dedupe a nivel de
            #    aplicacion (`Skipped`), sin metrica nueva de ledger. Para tener un
            #    `dedupe_hit` real se reingesta el MISMO movimiento por otro canal
            #    (igual que `test_notification_dedupe.test_ac51_...`): otra fila
            #    `raw_messages` con la misma huella de captura.
            second_raw_message_id = await insert_raw_message(
                session_factory,
                user_id=user.id,
                channel="notification",
                external_id="metrics-dedupe-hit",
                body=(
                    "Bancolombia: Compraste $176.824,00 en CARBON Y XILVESTRE T con tu "
                    "T.Deb *1234, el 01/05/2026 a las 16:00."
                ),
                status="pending",
                received_at=_COMPRA_TDEB.received_at,
            )
            await bus.publish(
                RawMessageReceived(
                    event_id=uuid4(),
                    occurred_at=SystemClock().now(),
                    raw_message_id=second_raw_message_id,
                    user_id=user.id,
                    channel="notification",
                    bank="bancolombia",
                    received_at=_COMPRA_TDEB.received_at,
                )
            )

            # Evidencia positiva de consumo antes de asertar: "sigue habiendo 1
            # transaccion" ya es cierto ANTES de que el consumer lea el evento, asi
            # que por si solo el wait retornaria en el primer poll (mismo agujero
            # que AC-5.2 en `test_notification_dedupe.py`).
            async def second_message_consumed() -> bool:
                return await pipeline_drained(redis_client, bus)

            assert await harness.wait_for(second_message_consumed)
            assert await count_transactions(session_factory, user.id) == 1

            # 3) un mensaje que va a revision (outcome=sent_to_review, LLM deshabilitado).
            third_raw_message_id = await insert_raw_message(
                session_factory,
                user_id=user.id,
                external_id="metrics-review",
                body=_NO_TEMPLATE_BODY,
                status="pending",
                received_at=_NO_TEMPLATE_RECEIVED_AT,
            )
            await bus.publish(
                RawMessageReceived(
                    event_id=uuid4(),
                    occurred_at=SystemClock().now(),
                    raw_message_id=third_raw_message_id,
                    user_id=user.id,
                    channel="email",
                    bank="bancolombia",
                    received_at=_NO_TEMPLATE_RECEIVED_AT,
                )
            )

            async def has_review_entry() -> bool:
                return await review_reason(session_factory, third_raw_message_id) is not None

            assert await harness.wait_for(has_review_entry)
    finally:
        await harness.stop()

    metrics = [e for e in captured if e.get("event") == "parsing_metric"]
    assert metrics, "se esperaba al menos una metrica parsing_metric"

    for metric in metrics:
        assert metric["outcome"] in _ALLOWED_OUTCOMES
        assert set(metric.keys()) <= _ALLOWED_KEYS

    for entry in captured:
        rendered = repr(entry)
        assert _AMOUNT not in rendered
        assert _MERCHANT not in rendered
