"""Tests de integracion del job de reencolado (`requeue_pending_raw_messages`,
riesgo 4 / D9: republica `RawMessageReceived` para `raw_messages` `pending`
huerfanos, cerrando el hueco "commit ok + publish fallo" sin outbox. F3.7
adelantado en F2 - Task 10.
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

from finanzia.events_registry import build_registry
from finanzia.modules.ingestion import public
from finanzia.shared.clock import SystemClock
from finanzia.shared.events.redis_streams import RedisStreamsEventBus
from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration


async def _set_updated_at(
    session_factory: async_sessionmaker[AsyncSession], raw_message_id: UUID, updated_at: datetime
) -> None:
    async with session_factory() as session:
        await session.execute(
            text("UPDATE raw_messages SET updated_at = :updated_at WHERE id = :id"),
            {"updated_at": updated_at, "id": raw_message_id},
        )
        await session.commit()


async def _set_requeue_attempts(
    session_factory: async_sessionmaker[AsyncSession], raw_message_id: UUID, attempts: int
) -> None:
    async with session_factory() as session:
        await session.execute(
            text("UPDATE raw_messages SET requeue_attempts = :n WHERE id = :id"),
            {"n": attempts, "id": raw_message_id},
        )
        await session.commit()


async def _stream_entries(settings: Settings, event_type: str) -> list[object]:
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        entries = await client.xrange(f"finanzia:events:{event_type}")
        registry = build_registry()
        return [registry.decode(fields) for _, fields in entries]
    finally:
        await client.aclose()


async def test_requeue_republica_solo_el_pending_huerfano_y_no_los_otros_dos(
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    now = datetime.now(UTC)

    huerfano = await insert_raw_message(
        session_factory, user_id=user.id, external_id="requeue-huerfano", status="pending"
    )
    reciente = await insert_raw_message(
        session_factory, user_id=user.id, external_id="requeue-reciente", status="pending"
    )
    ya_parseado = await insert_raw_message(
        session_factory, user_id=user.id, external_id="requeue-parsed", status="parsed"
    )

    await _set_updated_at(session_factory, huerfano, now - timedelta(minutes=20))
    await _set_updated_at(session_factory, reciente, now - timedelta(minutes=5))
    await _set_updated_at(session_factory, ya_parseado, now - timedelta(minutes=20))

    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    clock = SystemClock()

    try:
        async with session_factory() as session:
            summary = await public.requeue_pending_raw_messages(session, bus, clock)
        assert summary.requeued == 1
        assert summary.exhausted == 0

        all_entries = await _stream_entries(settings, "ingestion.RawMessageReceived")
        matching = [e for e in all_entries if e.raw_message_id == huerfano]  # type: ignore[attr-defined]
        assert len(matching) == 1
        event = matching[0]
        assert event.user_id == user.id  # type: ignore[attr-defined]
        assert event.channel == "email"  # type: ignore[attr-defined]

        assert not any(e.raw_message_id == reciente for e in all_entries)  # type: ignore[attr-defined]
        assert not any(e.raw_message_id == ya_parseado for e in all_entries)  # type: ignore[attr-defined]

        # Segunda corrida inmediata: `huerfano` ya fue "tocado" (updated_at
        # actualizado), no vuelve a contar dentro de la misma ventana de 10 min.
        async with session_factory() as session:
            second = await public.requeue_pending_raw_messages(session, bus, clock)
        assert second.requeued == 0
    finally:
        await redis_client.aclose()


async def test_requeue_agota_la_fila_tras_el_maximo_de_republicaciones(
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """Riesgo 4 / D9: a la republicacion numero `max_attempts + 1` la fila pasa a
    `failed` y deja de ser candidata (fin del ciclo cron -> DLQ -> `pending` -> cron).
    """
    user = await user_factory()
    now = datetime.now(UTC)

    agotado = await insert_raw_message(
        session_factory, user_id=user.id, external_id="requeue-agotado", status="pending"
    )
    await _set_updated_at(session_factory, agotado, now - timedelta(minutes=20))
    await _set_requeue_attempts(session_factory, agotado, 5)

    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    clock = SystemClock()

    try:
        async with session_factory() as session:
            summary = await public.requeue_pending_raw_messages(session, bus, clock)
        assert summary.requeued == 0
        assert summary.exhausted == 1

        all_entries = await _stream_entries(settings, "ingestion.RawMessageReceived")
        assert not any(e.raw_message_id == agotado for e in all_entries)  # type: ignore[attr-defined]

        async with session_factory() as session:
            status = (
                await session.execute(
                    text("SELECT status FROM raw_messages WHERE id = :id"), {"id": agotado}
                )
            ).scalar_one()
        assert status == "failed"
    finally:
        await redis_client.aclose()
