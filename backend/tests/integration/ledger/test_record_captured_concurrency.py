"""Tests de concurrencia de `record_captured_transaction` (facade, AC-5.1/5.2, ADR-7).

Dos sesiones independientes ejecutan la fachada publica de ledger contra la misma
captura (o dos capturas del mismo evento por canales distintos) via `asyncio.gather`:
el dedupe de `insert_if_absent` (`ON CONFLICT DO NOTHING`) garantiza una unica
transaccion, y solo la ejecucion que la crea publica `TransactionCaptured`.
"""

import asyncio
from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID

import pytest
import redis.asyncio as redis_asyncio
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.raw_messages import insert_raw_message

from finanzia.events_registry import build_registry
from finanzia.modules.ledger.domain.enums import Bank, Channel, Direction
from finanzia.modules.ledger.public import (
    CapturedTransactionCommand,
    Recorded,
    SourceInput,
    record_captured_transaction,
)
from finanzia.shared.clock import SystemClock
from finanzia.shared.events.redis_streams import RedisStreamsEventBus
from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration


def _cmd(
    *,
    user_id: UUID,
    raw_message_id: UUID,
    occurred_at: datetime,
    channel: Channel = Channel.EMAIL,
) -> CapturedTransactionCommand:
    return CapturedTransactionCommand(
        user_id=user_id,
        bank=Bank.BANCOLOMBIA,
        amount=Decimal("50000.00"),
        direction=Direction.DEBIT,
        occurred_at=occurred_at,
        last4="1234",
        merchant="Rappi",
        description=None,
        suggested_category_slug=None,
        parsed_by="rule:bancolombia:debito",
        confidence=0.9,
        source=SourceInput(
            channel=channel,
            raw_message_id=raw_message_id,
            received_at=occurred_at,
        ),
    )


async def _count_transactions(
    session_factory: async_sessionmaker[AsyncSession], user_id: object
) -> int:
    async with session_factory() as session:
        return (
            await session.execute(
                text("SELECT count(*) FROM transactions WHERE user_id = :u"), {"u": user_id}
            )
        ).scalar_one()


async def _count_sources(session_factory: async_sessionmaker[AsyncSession], user_id: object) -> int:
    async with session_factory() as session:
        return (
            await session.execute(
                text(
                    "SELECT count(*) FROM transaction_sources ts "
                    "JOIN transactions t ON t.id = ts.transaction_id "
                    "WHERE t.user_id = :u"
                ),
                {"u": user_id},
            )
        ).scalar_one()


async def _stream_entries(settings: Settings, event_type: str) -> list[dict[bytes, bytes]]:
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        entries = await client.xrange(f"finanzia:events:{event_type}")
        return [fields for _, fields in entries]
    finally:
        await client.aclose()


async def test_dos_sesiones_concurrentes_mismo_comando_generan_una_transaccion_y_una_fuente(
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    clock = SystemClock()
    occurred_at = datetime(2026, 2, 1, 12, 0, tzinfo=UTC)
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id)
    cmd = _cmd(user_id=user.id, raw_message_id=raw_message_id, occurred_at=occurred_at)

    async def _run() -> Recorded:
        async with session_factory() as session:
            return await record_captured_transaction(session, bus, clock, cmd)

    try:
        results = await asyncio.gather(_run(), _run())
    finally:
        await redis_client.aclose()

    assert sum(1 for r in results if r.created) == 1
    assert await _count_transactions(session_factory, user.id) == 1
    assert await _count_sources(session_factory, user.id) == 1

    entries = await _stream_entries(settings, "ledger.TransactionCaptured")
    assert len(entries) == 1


async def test_email_y_notificacion_concurrentes_generan_una_transaccion_y_dos_fuentes(
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    clock = SystemClock()
    occurred_at = datetime(2026, 2, 1, 12, 0, tzinfo=UTC)

    email_raw_message_id = await insert_raw_message(
        session_factory, user_id=user.id, channel="email", external_id="email-concurrente"
    )
    notification_raw_message_id = await insert_raw_message(
        session_factory, user_id=user.id, channel="notification", external_id="notif-concurrente"
    )
    email_cmd = _cmd(
        user_id=user.id,
        raw_message_id=email_raw_message_id,
        occurred_at=occurred_at,
        channel=Channel.EMAIL,
    )
    notification_cmd = _cmd(
        user_id=user.id,
        raw_message_id=notification_raw_message_id,
        occurred_at=occurred_at + timedelta(seconds=40),
        channel=Channel.NOTIFICATION,
    )

    async def _run(cmd: CapturedTransactionCommand) -> Recorded:
        async with session_factory() as session:
            return await record_captured_transaction(session, bus, clock, cmd)

    try:
        results = await asyncio.gather(_run(email_cmd), _run(notification_cmd))
    finally:
        await redis_client.aclose()

    assert sum(1 for r in results if r.created) == 1
    assert await _count_transactions(session_factory, user.id) == 1
    assert await _count_sources(session_factory, user.id) == 2

    entries = await _stream_entries(settings, "ledger.TransactionCaptured")
    assert len(entries) == 1
