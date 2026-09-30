"""Tests de integracion de la fachada publica de ingestion (spec 006 §2.2-2.3, §4.4,
AC-2.4, D2, D9, P1/P6).

Ejercita `ingestion.public` de punta a punta contra Postgres + Redis reales, con los
fixtures de correo de F2.3 (`tests/fixtures/emails`).
"""

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
import redis.asyncio as redis_asyncio
import structlog.testing
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.email_fixtures import FIXTURES_DIR, bancolombia_fixtures, load_email_fixtures

from luka.events_registry import build_registry
from luka.modules.ingestion import public
from luka.modules.ingestion.application.dto import Accepted, Discarded, RawMessageInput
from luka.modules.ingestion.domain.enums import Channel, RawMessageStatus
from luka.shared.clock import SystemClock
from luka.shared.events.redis_streams import RedisStreamsEventBus
from luka.shared.settings import Settings

pytestmark = pytest.mark.integration


async def _row_count(session_factory: async_sessionmaker[AsyncSession], user_id: object) -> int:
    async with session_factory() as session:
        return (
            await session.execute(
                text("SELECT count(*) FROM raw_messages WHERE user_id = :u"), {"u": user_id}
            )
        ).scalar_one()


async def _stream_entries(settings: Settings, event_type: str) -> list[object]:
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        entries = await client.xrange(f"luka:events:{event_type}")
        registry = build_registry()
        return [registry.decode(fields) for _, fields in entries]
    finally:
        await client.aclose()


async def test_ingesta_de_compra_tdeb_bancolombia_inserta_fila_pending_y_publica_evento(
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    fixture = next(f for f in bancolombia_fixtures() if f.name == "compra_tdeb.txt")

    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    clock = SystemClock()
    input_ = RawMessageInput(
        user_id=user.id,
        channel=Channel.EMAIL,
        external_id="gmail-msg-compra-tdeb",
        sender=fixture.sender,
        title=None,
        text=fixture.body,
        received_at=fixture.received_at,
    )

    try:
        with structlog.testing.capture_logs() as captured:
            async with session_factory() as session:
                outcome = await public.ingest_raw_message(session, bus, clock, input_)

        assert isinstance(outcome, Accepted)
        assert outcome.bank == "bancolombia"
        assert await _row_count(session_factory, user.id) == 1

        metric_logs = [entry for entry in captured if entry.get("event") == "parsing_metric"]
        assert len(metric_logs) == 1
        assert metric_logs[0]["outcome"] == "accepted"
        assert metric_logs[0]["channel"] == "email"
        assert metric_logs[0]["bank"] == "bancolombia"

        async with session_factory() as session:
            view = await public.get_raw_message_for_parsing(session, outcome.raw_message_id)
        assert view is not None
        assert view.status == RawMessageStatus.PENDING
        assert view.bank == "bancolombia"
        assert view.body == fixture.body.strip()

        entries = [
            e
            for e in await _stream_entries(settings, "ingestion.RawMessageReceived")
            if e.raw_message_id == outcome.raw_message_id  # type: ignore[attr-defined]
        ]
        assert len(entries) == 1
        event = entries[0]
        assert event.user_id == user.id  # type: ignore[attr-defined]
        assert event.bank == "bancolombia"  # type: ignore[attr-defined]
        assert event.channel == "email"  # type: ignore[attr-defined]
    finally:
        await redis_client.aclose()


async def test_ingesta_de_correo_nu_se_descarta_sin_persistir_ni_filtrar_datos_en_logs(
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    fixture = load_email_fixtures(FIXTURES_DIR / "other")[0]
    assert fixture.name == "nu_pago.txt"

    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    clock = SystemClock()
    input_ = RawMessageInput(
        user_id=user.id,
        channel=Channel.EMAIL,
        external_id="gmail-msg-nu-pago",
        sender=fixture.sender,
        title=None,
        text=fixture.body,
        received_at=fixture.received_at,
    )

    try:
        with structlog.testing.capture_logs() as captured:
            async with session_factory() as session:
                outcome = await public.ingest_raw_message(session, bus, clock, input_)

        assert outcome == Discarded("unsupported_sender")
        assert await _row_count(session_factory, user.id) == 0

        for entry in captured:
            rendered = repr(entry)
            assert "CORREDORES" not in rendered
            assert fixture.sender not in rendered
    finally:
        await redis_client.aclose()


async def test_mark_raw_message_actualiza_estado_sin_comitear_hasta_que_el_llamador_lo_haga(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    now = datetime.now(UTC)

    async with session_factory() as session:
        result = await session.execute(
            text(
                "INSERT INTO raw_messages "
                "(user_id, channel, external_id, sender, bank, body, status, "
                " received_at, purge_after) VALUES "
                "(:user_id, 'email', 'mark-1', 'x@bancolombia.com.co', 'bancolombia', "
                " 'cuerpo', 'pending', :now, :purge_after) RETURNING id"
            ),
            {"user_id": user.id, "now": now, "purge_after": now + timedelta(days=90)},
        )
        raw_message_id = result.scalar_one()
        await session.commit()

    async with session_factory() as session:
        updated = await public.mark_raw_message(session, raw_message_id, "parsed", now)
        await session.commit()
    assert updated is True

    async with session_factory() as session:
        view = await public.get_raw_message_for_parsing(session, raw_message_id)
    assert view is not None
    assert view.status == RawMessageStatus.PARSED


async def test_load_raw_messages_for_review_indexa_por_id(
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    clock = SystemClock()

    try:
        async with session_factory() as session:
            outcome = await public.ingest_raw_message(
                session,
                bus,
                clock,
                RawMessageInput(
                    user_id=user.id,
                    channel=Channel.EMAIL,
                    external_id="review-1",
                    sender="alertasynotificaciones@an.notificacionesbancolombia.com",
                    title=None,
                    text="Bancolombia: Compraste $1.00 en X con tu T.Deb *1234, "
                    "el 01/01/2026 a las 10:00.",
                    received_at=datetime(2026, 1, 1, tzinfo=UTC),
                ),
            )
        assert isinstance(outcome, Accepted)

        async with session_factory() as session:
            views = await public.load_raw_messages_for_review(
                session, user.id, [outcome.raw_message_id]
            )
        assert outcome.raw_message_id in views
        assert views[outcome.raw_message_id].bank == "bancolombia"

        async with session_factory() as session:
            missing = await public.load_raw_messages_for_review(session, user.id, [uuid4()])
        assert missing == {}
    finally:
        await redis_client.aclose()


async def test_purge_expired_bodies_anula_body_de_filas_vencidas_y_conserva_el_status(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    now = datetime.now(UTC)
    past_received = now - timedelta(days=200)
    past_purge_after = now - timedelta(days=110)

    async with session_factory() as session:
        result = await session.execute(
            text(
                "INSERT INTO raw_messages "
                "(user_id, channel, external_id, sender, bank, body, status, "
                " received_at, purge_after) VALUES "
                "(:user_id, 'email', 'purge-1', 'x@bancolombia.com.co', 'bancolombia', "
                " 'cuerpo viejo', 'parsed', :received_at, :purge_after) RETURNING id"
            ),
            {"user_id": user.id, "received_at": past_received, "purge_after": past_purge_after},
        )
        raw_message_id = result.scalar_one()
        await session.commit()

    async with session_factory() as session:
        count = await public.purge_expired_bodies(session, now)
    assert count == 1

    async with session_factory() as session:
        view = await public.get_raw_message_for_parsing(session, raw_message_id)
    assert view is not None
    assert view.body is None
    assert view.status == RawMessageStatus.PARSED
