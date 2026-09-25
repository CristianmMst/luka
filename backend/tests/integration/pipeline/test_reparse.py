"""Tests e2e del reparse (spec 005 §7, spec 006 §4.4): un mensaje `failed` con item
de revision abierto vuelve al pipeline; si ahora parsea, la transaccion existe y el
item queda `reparsed`; si vuelve a fallar, el item sigue abierto y no se duplica.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import pytest
from sqlalchemy import text
from support.clock import FixedClock
from support.email_fixtures import bancolombia_fixtures
from support.pipeline import (
    InMemoryBudget,
    PipelineHarness,
    count_transactions,
    pipeline_drained,
    raw_status,
)
from support.raw_messages import insert_raw_message

from finanzia.modules.ingestion import public as ingestion_public
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
# Ninguna plantilla lo reconoce y el LLM esta deshabilitado: vuelve a fallar.
_UNPARSEABLE_BODY = "Bancolombia: Retiraste $50.000 en cajero El Poblado el 01/01/2026."


async def _failed_with_open_review(
    session_factory: async_sessionmaker[AsyncSession], user_id: UUID, *, body: str
) -> UUID:
    """Un `raw_message` `failed` con su item de revision abierto (como lo deja parsing)."""
    raw_message_id = await insert_raw_message(
        session_factory,
        user_id=user_id,
        sender=_COMPRA_TDEB.sender,
        body=body,
        status="failed",
        received_at=_COMPRA_TDEB.received_at,
    )
    async with session_factory() as session:
        await session.execute(
            text(
                "INSERT INTO review_queue (raw_message_id, user_id, reason) "
                "VALUES (:r, :u, 'no_template')"
            ),
            {"r": raw_message_id, "u": user_id},
        )
        await session.commit()
    return raw_message_id


async def _review_rows(session_factory: async_sessionmaker[AsyncSession], raw_message_id: UUID):
    async with session_factory() as session:
        return (
            await session.execute(
                text("SELECT resolution, resolved_at FROM review_queue WHERE raw_message_id = :r"),
                {"r": raw_message_id},
            )
        ).all()


async def _start(
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
) -> PipelineHarness:
    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=SystemClock(),
        llm=DisabledLlmParser(),
        budget=InMemoryBudget(),
        settings=settings,
    )
    return harness


async def test_reparse_convierte_el_fallido_y_cierra_su_revision(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    client: AsyncClient,
) -> None:
    user = await user_factory()
    # Un correo que hoy si reconoce una plantilla (la que "llego despues").
    raw_message_id = await _failed_with_open_review(
        session_factory, user.id, body=_COMPRA_TDEB.body
    )
    clock = FixedClock(_COMPRA_TDEB.received_at)

    harness = await _start(session_factory, redis_client, registry, bus, settings)
    try:
        async with session_factory() as session:
            summary = await ingestion_public.reparse_failed_raw_messages(session, bus, clock)
        assert summary.reparsed == 1

        async def converted() -> bool:
            rows = await _review_rows(session_factory, raw_message_id)
            return await count_transactions(session_factory, user.id) == 1 and bool(
                rows and rows[0].resolution == "reparsed"
            )

        assert await harness.wait_for(converted)

        # Segunda corrida: la fila ya esta `parsed`, no hay nada que reprocesar.
        async with session_factory() as session:
            second = await ingestion_public.reparse_failed_raw_messages(session, bus, clock)
        assert second.reparsed == 0
        assert await harness.wait_for(lambda: pipeline_drained(redis_client, bus))
    finally:
        await harness.stop()

    assert await raw_status(session_factory, raw_message_id) == "parsed"
    assert await count_transactions(session_factory, user.id) == 1
    rows = await _review_rows(session_factory, raw_message_id)
    assert len(rows) == 1
    assert rows[0].resolved_at is not None

    response = await client.get("/v1/review", headers=user.headers)
    assert response.status_code == 200, response.text
    assert response.json()["items"] == []


async def test_reparse_que_vuelve_a_fallar_deja_el_mismo_item_abierto(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    client: AsyncClient,
) -> None:
    user = await user_factory()
    raw_message_id = await _failed_with_open_review(
        session_factory, user.id, body=_UNPARSEABLE_BODY
    )
    clock = SystemClock()

    harness = await _start(session_factory, redis_client, registry, bus, settings)
    try:
        for _ in range(2):
            async with session_factory() as session:
                summary = await ingestion_public.reparse_failed_raw_messages(session, bus, clock)
            assert summary.reparsed == 1

            async def failed_again() -> bool:
                return await raw_status(session_factory, raw_message_id) == "failed"

            assert await harness.wait_for(failed_again)
            assert await harness.wait_for(lambda: pipeline_drained(redis_client, bus))
    finally:
        await harness.stop()

    assert await count_transactions(session_factory, user.id) == 0
    rows = await _review_rows(session_factory, raw_message_id)
    assert len(rows) == 1
    assert rows[0].resolution is None

    response = await client.get("/v1/review", headers=user.headers)
    assert response.status_code == 200, response.text
    assert [i["raw_message_id"] for i in response.json()["items"]] == [str(raw_message_id)]
