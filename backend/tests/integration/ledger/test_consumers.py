"""Tests de integracion de los consumers de `parsing.TransactionParsed`/`ParseFailed`
(spec 003 SS2.3, D4, D7, F2.6).
"""

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime
from decimal import Decimal
from uuid import UUID, uuid4

import pytest
import redis.asyncio as redis_asyncio
import structlog.testing
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.raw_messages import insert_raw_message

from luka.events_registry import build_registry
from luka.modules.ledger.infrastructure.consumers import make_transaction_parsed_handler
from luka.modules.parsing.domain.enums import Direction as ParsingDirection
from luka.modules.parsing.events import TransactionParsed
from luka.shared.clock import SystemClock
from luka.shared.events.redis_streams import RedisStreamsEventBus
from luka.shared.settings import Settings

pytestmark = pytest.mark.integration

_MERCHANT = "OXXO CALLE 59"
_AMOUNT = "53900.00"


def _event(  # noqa: PLR0913 - builder de evento con un default por campo
    *,
    raw_message_id: UUID,
    user_id: UUID,
    event_id: UUID | None = None,
    bank: str = "bancolombia",
    last4: str | None = "1234",
    amount: Decimal = Decimal(_AMOUNT),
) -> TransactionParsed:
    return TransactionParsed(
        event_id=event_id or uuid4(),
        occurred_at=datetime.now(UTC),
        raw_message_id=raw_message_id,
        user_id=user_id,
        channel="email",
        bank=bank,
        amount=amount,
        direction=ParsingDirection.DEBIT,
        transaction_occurred_at=datetime(2026, 9, 19, 21, 52, tzinfo=UTC),
        last4=last4,
        merchant=_MERCHANT,
        suggested_category=None,
        parsed_by="rule:bancolombia:compra_tdeb:v1",
        confidence=None,
        received_at=datetime.now(UTC),
    )


async def _create_account(client: AsyncClient, headers: dict[str, str]) -> str:
    response = await client.post(
        "/v1/accounts",
        json={"bank": "bancolombia", "kind": "credit_card", "last4": "1234"},
        headers=headers,
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


async def test_transaction_parsed_crea_transaccion_con_cuenta_y_fuente(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    account_id = await _create_account(client, user.headers)
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id)

    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    handler = make_transaction_parsed_handler(
        session_factory=session_factory, event_bus=bus, clock=SystemClock()
    )
    try:
        await handler(_event(raw_message_id=raw_message_id, user_id=user.id))
    finally:
        await redis_client.aclose()

    async with session_factory() as session:
        row = (
            await session.execute(
                text(
                    "SELECT t.parsed_by, t.account_id, ts.raw_message_id, ts.channel "
                    "FROM transactions t JOIN transaction_sources ts ON ts.transaction_id = t.id "
                    "WHERE t.user_id = :u"
                ),
                {"u": str(user.id)},
            )
        ).one()

    assert row.parsed_by == "rule:bancolombia:compra_tdeb:v1"
    assert str(row.account_id) == account_id
    assert str(row.raw_message_id) == str(raw_message_id)
    assert row.channel == "email"


async def test_reentrega_con_event_id_distinto_dedupe_y_loguea_metrica(
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id)

    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    handler = make_transaction_parsed_handler(
        session_factory=session_factory, event_bus=bus, clock=SystemClock()
    )
    try:
        await handler(_event(raw_message_id=raw_message_id, user_id=user.id))
        with structlog.testing.capture_logs() as captured:
            await handler(_event(raw_message_id=raw_message_id, user_id=user.id, event_id=uuid4()))
    finally:
        await redis_client.aclose()

    async with session_factory() as session:
        tx_count = (
            await session.execute(
                text("SELECT count(*) FROM transactions WHERE user_id = :u"), {"u": str(user.id)}
            )
        ).scalar_one()
        source_count = (
            await session.execute(
                text(
                    "SELECT count(*) FROM transaction_sources ts "
                    "JOIN transactions t ON t.id = ts.transaction_id WHERE t.user_id = :u"
                ),
                {"u": str(user.id)},
            )
        ).scalar_one()
    assert tx_count == 1
    assert source_count == 1

    dedupe_logs = [e for e in captured if e.get("event") == "parsing_metric"]
    assert len(dedupe_logs) == 1
    assert dedupe_logs[0]["outcome"] == "dedupe_hit"
    assert dedupe_logs[0]["bank"] == "bancolombia"
    assert dedupe_logs[0]["channel"] == "email"


async def test_bank_desconocido_cae_en_other(
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id)

    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    handler = make_transaction_parsed_handler(
        session_factory=session_factory, event_bus=bus, clock=SystemClock()
    )
    try:
        await handler(
            _event(
                raw_message_id=raw_message_id,
                user_id=user.id,
                bank="no_es_un_banco",
                last4=None,
            )
        )
    finally:
        await redis_client.aclose()

    async with session_factory() as session:
        bank = (
            await session.execute(
                text("SELECT bank FROM transactions WHERE user_id = :u"), {"u": str(user.id)}
            )
        ).scalar_one()
    assert bank == "other"


async def test_handler_no_filtra_amount_merchant_ni_body_en_logs(
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id)

    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    handler = make_transaction_parsed_handler(
        session_factory=session_factory, event_bus=bus, clock=SystemClock()
    )
    try:
        with structlog.testing.capture_logs() as captured:
            await handler(_event(raw_message_id=raw_message_id, user_id=user.id))
    finally:
        await redis_client.aclose()

    for entry in captured:
        rendered = repr(entry)
        assert _AMOUNT not in rendered
        assert "53900" not in rendered
        assert _MERCHANT not in rendered


@pytest.mark.parametrize("resolution", ["converted", "discarded"])
async def test_transaction_parsed_de_un_item_ya_resuelto_no_duplica(
    resolution: str,
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """Carrera reparse vs. convert/discard (spec 006 SS4.4): el `TransactionParsed`
    del mensaje reprocesado llega despues de que el usuario resolvio el item. El
    handler lo da por atendido (no lanza, sin reintento) y no crea transaccion.
    """
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id)
    async with session_factory() as session:
        await session.execute(
            text(
                "INSERT INTO review_queue (raw_message_id, user_id, reason, resolution, "
                "resolved_at) VALUES (:r, :u, 'no_template', :res, now())"
            ),
            {"r": raw_message_id, "u": user.id, "res": resolution},
        )
        await session.commit()

    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    handler = make_transaction_parsed_handler(
        session_factory=session_factory, event_bus=bus, clock=SystemClock()
    )
    try:
        with structlog.testing.capture_logs() as captured:
            await handler(_event(raw_message_id=raw_message_id, user_id=user.id))
    finally:
        await redis_client.aclose()

    async with session_factory() as session:
        tx_count = (
            await session.execute(
                text("SELECT count(*) FROM transactions WHERE user_id = :u"), {"u": str(user.id)}
            )
        ).scalar_one()
        stored = (
            await session.execute(
                text("SELECT resolution FROM review_queue WHERE raw_message_id = :r"),
                {"r": raw_message_id},
            )
        ).scalar_one()

    assert tx_count == 0
    assert stored == resolution
    skipped = [e for e in captured if e["event"] == "ledger_capture_skipped"]
    assert skipped == [
        {
            "event": "ledger_capture_skipped",
            "log_level": "info",
            "reason": "review_already_resolved",
            "bank": "bancolombia",
            "channel": "email",
        }
    ]
