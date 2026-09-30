"""Tests de integracion de `ingestion.public.reparse_failed_raw_messages` (spec 005
§7): las filas `failed` con cuerpo vuelven a `pending` y su `RawMessageReceived`
se republica; los cuerpos purgados y las filas en otro estado no se tocan.
"""

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta
from uuid import UUID

import pytest
import redis.asyncio as redis_asyncio
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.raw_messages import insert_raw_message

from luka.events_registry import build_registry
from luka.modules.ingestion import public
from luka.shared.clock import SystemClock
from luka.shared.events.redis_streams import RedisStreamsEventBus
from luka.shared.settings import Settings

pytestmark = pytest.mark.integration


async def _row(session_factory: async_sessionmaker[AsyncSession], raw_message_id: UUID):
    async with session_factory() as session:
        return (
            await session.execute(
                text("SELECT status, requeue_attempts FROM raw_messages WHERE id = :id"),
                {"id": raw_message_id},
            )
        ).one()


async def _republished_ids(settings: Settings) -> list[UUID]:
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        entries = await client.xrange("luka:events:ingestion.RawMessageReceived")
        registry = build_registry()
        return [registry.decode(fields).raw_message_id for _, fields in entries]  # type: ignore[attr-defined]
    finally:
        await client.aclose()


async def test_reparse_reencola_solo_fallidos_con_cuerpo_y_una_sola_vez(
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    redis_clean: None,
) -> None:
    del redis_clean
    user = await user_factory()
    otro = await user_factory(sub="sub-2", email="beatriz@example.com")
    now = datetime.now(UTC)

    fallido = await insert_raw_message(
        session_factory, user_id=user.id, status="failed", received_at=now - timedelta(days=1)
    )
    viejo = await insert_raw_message(
        session_factory, user_id=user.id, status="failed", received_at=now - timedelta(days=20)
    )
    purgado = await insert_raw_message(
        session_factory, user_id=user.id, status="failed", body=None, received_at=now
    )
    ajeno = await insert_raw_message(session_factory, user_id=otro.id, status="failed")
    revisado = await insert_raw_message(session_factory, user_id=user.id, status="reviewed")
    async with session_factory() as session:
        await session.execute(
            text("UPDATE raw_messages SET requeue_attempts = 5 WHERE id = :id"), {"id": fallido}
        )
        await session.commit()

    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    clock = SystemClock()
    try:
        async with session_factory() as session:
            summary = await public.reparse_failed_raw_messages(
                session, bus, clock, user_id=user.id, since=now - timedelta(days=7)
            )
        assert summary == public.ReparseSummary(reparsed=1)
        assert await _republished_ids(settings) == [fallido]

        estado = await _row(session_factory, fallido)
        assert (estado.status, estado.requeue_attempts) == ("pending", 0)
        for untouched, status in (
            (viejo, "failed"),
            (purgado, "failed"),
            (ajeno, "failed"),
            (revisado, "reviewed"),
        ):
            assert (await _row(session_factory, untouched)).status == status

        # Segunda corrida: la fila ya esta `pending`, no se republica otra vez.
        async with session_factory() as session:
            second = await public.reparse_failed_raw_messages(
                session, bus, clock, user_id=user.id, since=now - timedelta(days=7)
            )
        assert second.reparsed == 0
        assert await _republished_ids(settings) == [fallido]

        # Sin filtros toma a todos los usuarios y cualquier fecha (salvo el purgado).
        async with session_factory() as session:
            todos = await public.reparse_failed_raw_messages(session, bus, clock)
        assert todos.reparsed == 2
        assert set(await _republished_ids(settings)) == {fallido, viejo, ajeno}
        assert (await _row(session_factory, purgado)).status == "failed"
    finally:
        await redis_client.aclose()
