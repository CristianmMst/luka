"""Tests e2e de dedupe/reentrega (spec 004 SS3, AC-5.1/5.2/5.3, F2.2/F2.5/F2.6)."""

from __future__ import annotations

import hashlib
from datetime import timedelta
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest
import structlog.testing
from sqlalchemy import text
from support.clock import FixedClock
from support.email_fixtures import bancolombia_fixtures
from support.pipeline import InMemoryBudget, PipelineHarness, count_sources, count_transactions

from finanzia.modules.ingestion.application.dto import RawMessageInput
from finanzia.modules.ingestion.domain.enums import Channel
from finanzia.modules.ingestion.events import RawMessageReceived
from finanzia.modules.ingestion.public import Accepted, Duplicate, ingest_raw_message
from finanzia.modules.parsing.infrastructure.llm.disabled import DisabledLlmParser
from finanzia.shared.clock import SystemClock

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable
    from uuid import UUID

    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
    from support.auth import AuthedUser

    from finanzia.shared.events.codec import EventRegistry
    from finanzia.shared.events.redis_streams import RedisStreamsEventBus
    from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration

_COMPRA_TDEB = next(f for f in bancolombia_fixtures() if f.name == "compra_tdeb.txt")
_COMPRA_TDEB_2 = next(f for f in bancolombia_fixtures() if f.name == "compra_tdeb_2.txt")


async def _create_account(client: AsyncClient, headers: dict[str, str], last4: str) -> None:
    response = await client.post(
        "/v1/accounts",
        json={"bank": "bancolombia", "kind": "savings", "last4": last4},
        headers=headers,
    )
    assert response.status_code == 201, response.text


async def _tx_id_for(session_factory: async_sessionmaker[AsyncSession], user_id: UUID) -> UUID:
    async with session_factory() as session:
        return (
            await session.execute(
                text("SELECT id FROM transactions WHERE user_id = :u"), {"u": str(user_id)}
            )
        ).scalar_one()


async def test_ac52_reingesta_y_reentrega_del_mismo_correo_no_duplica(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    await _create_account(client, user.headers, "1234")
    clock = FixedClock(_COMPRA_TDEB.received_at)

    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=clock,
        llm=DisabledLlmParser(),
        budget=InMemoryBudget(),  # nunca se invoca: los cuerpos matchean plantilla
        settings=settings,
    )
    try:
        message = RawMessageInput(
            user_id=user.id,
            channel=Channel.EMAIL,
            external_id=_COMPRA_TDEB.name,
            sender=_COMPRA_TDEB.sender,
            title=None,
            text=_COMPRA_TDEB.body,
            received_at=_COMPRA_TDEB.received_at,
        )
        async with session_factory() as session:
            first = await ingest_raw_message(session, bus, clock, message)
        assert isinstance(first, Accepted)
        raw_message_id = first.raw_message_id

        async def one_transaction() -> bool:
            return await count_transactions(session_factory, user.id) == 1

        assert await harness.wait_for(one_transaction)

        # Reingesta con el mismo `external_id`: la fila ya no esta `pending` (esta
        # `parsed`), asi que es un `Duplicate` sin republish (D9) y sin efecto.
        async with session_factory() as session:
            second = await ingest_raw_message(session, bus, clock, message)
        assert isinstance(second, Duplicate)
        assert second.republished is False

        # Reentrega manual a nivel de stream: una copia del mismo `RawMessageReceived`
        # (mismos campos) via `XADD`. El `raw_message` ya no esta `pending`, asi que
        # el handler de parsing la absorbe sin publicar nada nuevo (D8 idempotencia).
        redelivery = RawMessageReceived(
            event_id=uuid4(),
            occurred_at=SystemClock().now(),
            raw_message_id=raw_message_id,
            user_id=user.id,
            channel="email",
            bank="bancolombia",
            received_at=_COMPRA_TDEB.received_at,
        )
        await bus.publish(redelivery)

        async def still_one_transaction_and_one_source() -> bool:
            tx_id = await _tx_id_for(session_factory, user.id)
            return (
                await count_transactions(session_factory, user.id) == 1
                and await count_sources(session_factory, tx_id) == 1
            )

        assert await harness.wait_for(still_one_transaction_and_one_source)
    finally:
        await harness.stop()

    async with session_factory() as session:
        raw_count = (
            await session.execute(
                text("SELECT count(*) FROM raw_messages WHERE user_id = :u"), {"u": str(user.id)}
            )
        ).scalar_one()
    assert raw_count == 1


async def test_ac51_email_y_notificacion_del_mismo_movimiento_dedupean(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    await _create_account(client, user.headers, "1234")
    clock = FixedClock(_COMPRA_TDEB.received_at)

    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=clock,
        llm=DisabledLlmParser(),
        budget=InMemoryBudget(),  # nunca se invoca: los cuerpos matchean plantilla
        settings=settings,
    )
    try:
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

        async def one_transaction() -> bool:
            return await count_transactions(session_factory, user.id) == 1

        assert await harness.wait_for(one_transaction)
        tx_id = await _tx_id_for(session_factory, user.id)

        bancolombia_line = next(
            line for line in _COMPRA_TDEB.body.splitlines() if line.startswith("Bancolombia:")
        )
        client_hash = hashlib.sha256(b"ac-5.1-dedupe-test").hexdigest()

        with structlog.testing.capture_logs() as captured:
            response = await client.post(
                "/v1/ingest/notifications",
                json={
                    "items": [
                        {
                            "package": "com.bancolombia.app",
                            "channel": "notification",
                            "posted_at": (
                                _COMPRA_TDEB.received_at + timedelta(seconds=40)
                            ).isoformat(),
                            "text": bancolombia_line,
                            "client_hash": client_hash,
                        }
                    ]
                },
                headers=user.headers,
            )
            assert response.status_code == 200, response.text
            assert response.json() == {"accepted": 1, "duplicates": 0, "discarded": 0}

            async def two_sources() -> bool:
                return await count_sources(session_factory, tx_id) == 2

            assert await harness.wait_for(two_sources)
    finally:
        await harness.stop()

    # La notificacion tambien matchea plantilla (mismo texto), asi que produce
    # DOS `parsing_metric`: `parsed_by_rule` (parsing) y `dedupe_hit` (ledger,
    # al encontrar la transaccion ya creada por el correo).
    dedupe_logs = [
        e
        for e in captured
        if e.get("event") == "parsing_metric" and e.get("outcome") == "dedupe_hit"
    ]
    assert len(dedupe_logs) == 1
    assert dedupe_logs[0]["bank"] == "bancolombia"
    assert dedupe_logs[0]["channel"] == "notification"

    async with session_factory() as session:
        channels = set(
            (
                await session.execute(
                    text("SELECT channel FROM transaction_sources WHERE transaction_id = :t"),
                    {"t": str(tx_id)},
                )
            ).scalars()
        )
    assert channels == {"email", "notification"}


async def test_ac53_doce_minutos_de_diferencia_crea_dos_transacciones(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    await _create_account(client, user.headers, "1234")
    # Base = `compra_tdeb_2.txt` (hora 21:52): el `occurred_at` de cada plantilla
    # debe caer dentro de `received_at +/- 7 dias` (spec 006 SS4.1), asi que
    # `received_at` de cada mensaje se ancla a su propia hora de compra, no a la
    # de un fixture de mayo (`_COMPRA_TDEB`).
    clock = FixedClock(_COMPRA_TDEB_2.received_at)

    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=clock,
        llm=DisabledLlmParser(),
        budget=InMemoryBudget(),  # nunca se invoca: los cuerpos matchean plantilla
        settings=settings,
    )
    try:
        first_received_at = _COMPRA_TDEB_2.received_at
        second_received_at = _COMPRA_TDEB_2.received_at + timedelta(minutes=12)
        first_body = (
            "Bancolombia: Compraste $53.900,00 en OXXO CALLE 59 con tu T.Deb *1234, "
            "el 19/09/2026 a las 21:52."
        )
        second_body = (
            "Bancolombia: Compraste $53.900,00 en OXXO CALLE 59 con tu T.Deb *1234, "
            "el 19/09/2026 a las 22:04."
        )  # mismo comercio/monto, 12 minutos despues (fuera de la ventana de 10 min)

        async with session_factory() as session:
            first = await ingest_raw_message(
                session,
                bus,
                clock,
                RawMessageInput(
                    user_id=user.id,
                    channel=Channel.EMAIL,
                    external_id="ac-5.3-primera",
                    sender=_COMPRA_TDEB.sender,
                    title=None,
                    text=first_body,
                    received_at=first_received_at,
                ),
            )
            second = await ingest_raw_message(
                session,
                bus,
                clock,
                RawMessageInput(
                    user_id=user.id,
                    channel=Channel.EMAIL,
                    external_id="ac-5.3-segunda",
                    sender=_COMPRA_TDEB.sender,
                    title=None,
                    text=second_body,
                    received_at=second_received_at,
                ),
            )
        assert isinstance(first, Accepted)
        assert isinstance(second, Accepted)

        async def two_transactions() -> bool:
            return await count_transactions(session_factory, user.id) == 2

        assert await harness.wait_for(two_transactions)
    finally:
        await harness.stop()
