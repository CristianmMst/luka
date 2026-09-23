"""Tests de integracion de `/v1/transactions` (spec 005 SS6, SS9.3, F1.7)."""

from collections.abc import Awaitable, Callable
from dataclasses import replace
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import uuid4

import pytest
import redis.asyncio as redis_asyncio
from fastapi import FastAPI
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.raw_messages import insert_raw_message

from finanzia.events_registry import build_registry
from finanzia.modules.ledger.domain.enums import Bank, Channel, Direction
from finanzia.modules.ledger.domain.system_categories import SIN_CATEGORIA_ID
from finanzia.modules.ledger.public import (
    CapturedTransactionCommand,
    SourceInput,
    TransactionCaptured,
    record_captured_transaction,
)
from finanzia.shared.clock import SystemClock
from finanzia.shared.events.redis_streams import RedisStreamsEventBus
from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration

_BASE_BODY: dict[str, object] = {
    "amount": "10000.00",
    "direction": "debit",
    "occurred_at": "2026-01-01T12:00:00+00:00",
}


async def _post_transaction(
    client: AsyncClient, headers: dict[str, str], **overrides: object
) -> dict:
    body = {**_BASE_BODY, **overrides}
    response = await client.post("/v1/transactions", json=body, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


async def test_idempotency_key_repetida_devuelve_la_misma_respuesta_y_una_sola_fila(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    headers = {**user.headers, "Idempotency-Key": str(uuid4())}

    first = await client.post("/v1/transactions", json=_BASE_BODY, headers=headers)
    assert first.status_code == 201

    second = await client.post("/v1/transactions", json=_BASE_BODY, headers=headers)
    assert second.status_code == 201
    assert second.json() == first.json()
    assert second.headers.get("idempotency-replayed") == "true"

    listing = await client.get("/v1/transactions", headers=user.headers)
    assert len(listing.json()["items"]) == 1


async def test_post_sin_categoria_usa_sin_categoria(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    body = await _post_transaction(client, user.headers)
    assert body["category_id"] == str(SIN_CATEGORIA_ID)


async def test_amount_negativo_es_400_con_field_amount(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    response = await client.post(
        "/v1/transactions", json={**_BASE_BODY, "amount": "-5"}, headers=user.headers
    )
    assert response.status_code == 400
    assert response.json()["error"]["field"] == "amount"


async def test_amount_no_numerico_es_400_con_field_amount(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    response = await client.post(
        "/v1/transactions", json={**_BASE_BODY, "amount": "abc"}, headers=user.headers
    )
    assert response.status_code == 400
    assert response.json()["error"]["field"] == "amount"


async def test_occurred_at_naive_es_400(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    response = await client.post(
        "/v1/transactions",
        json={**_BASE_BODY, "occurred_at": "2026-01-01T12:00:00"},
        headers=user.headers,
    )
    assert response.status_code == 400


async def test_kind_income_con_direction_debit_es_400_con_field_kind(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    response = await client.post(
        "/v1/transactions",
        json={**_BASE_BODY, "direction": "debit", "kind": "income"},
        headers=user.headers,
    )
    assert response.status_code == 400
    assert response.json()["error"]["field"] == "kind"


async def test_kind_transfer_en_post_es_aceptado(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    body = await _post_transaction(client, user.headers, kind="transfer")
    assert body["kind"] == "transfer"
    assert body["fiscal_tag"] == "transferencia"


async def test_respuesta_amount_es_string_con_dos_decimales(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    body = await _post_transaction(client, user.headers, amount="152300")
    assert body["amount"] == "152300.00"
    assert isinstance(body["amount"], str)


async def test_get_incluye_source_manual(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    created = await _post_transaction(client, user.headers)
    response = await client.get(f"/v1/transactions/{created['id']}", headers=user.headers)
    assert response.status_code == 200
    assert response.json()["sources"][0]["channel"] == "manual"


async def test_get_incluye_source_nfc_cuando_se_envia_nfc_tag_id(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    created = await _post_transaction(client, user.headers, nfc_tag_id="tag-abc-123")
    response = await client.get(f"/v1/transactions/{created['id']}", headers=user.headers)
    assert response.json()["sources"][0]["channel"] == "nfc"


async def test_patch_category_id_aprende_regla_de_comercio(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    user = await user_factory()
    created = await _post_transaction(client, user.headers, merchant="Rappi Colombia SAS")

    category_resp = await client.post(
        "/v1/categories",
        json={"name": "Domicilios", "fiscal_tag": "no_deducible"},
        headers=user.headers,
    )
    assert category_resp.status_code == 201
    category_id = category_resp.json()["id"]

    patch_resp = await client.patch(
        f"/v1/transactions/{created['id']}",
        json={"category_id": category_id},
        headers=user.headers,
    )
    assert patch_resp.status_code == 200
    assert patch_resp.json()["category_id"] == category_id

    async with session_factory() as session:
        rules = (
            await session.execute(
                text("SELECT merchant_pattern, category_id FROM merchant_rules WHERE user_id = :u"),
                {"u": str(user.id)},
            )
        ).all()
    assert len(rules) == 1
    assert rules[0].merchant_pattern == "RAPPI COLOMBIA SAS"
    assert str(rules[0].category_id) == category_id


async def test_patch_category_id_con_learn_merchant_rule_false_no_crea_regla(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    user = await user_factory()
    created = await _post_transaction(client, user.headers, merchant="Rappi Colombia SAS")
    category_resp = await client.post(
        "/v1/categories",
        json={"name": "Domicilios 2", "fiscal_tag": "no_deducible"},
        headers=user.headers,
    )
    category_id = category_resp.json()["id"]

    patch_resp = await client.patch(
        f"/v1/transactions/{created['id']}",
        json={"category_id": category_id, "learn_merchant_rule": False},
        headers=user.headers,
    )
    assert patch_resp.status_code == 200

    async with session_factory() as session:
        rules = (
            await session.execute(
                text("SELECT count(*) FROM merchant_rules WHERE user_id = :u"),
                {"u": str(user.id)},
            )
        ).scalar_one()
    assert rules == 0


async def test_patch_kind_transfer_actualiza_fiscal_tag(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    created = await _post_transaction(client, user.headers)
    patch_resp = await client.patch(
        f"/v1/transactions/{created['id']}", json={"kind": "transfer"}, headers=user.headers
    )
    assert patch_resp.status_code == 200
    assert patch_resp.json()["fiscal_tag"] == "transferencia"
    assert patch_resp.json()["kind"] == "transfer"


async def _create_account(
    client: AsyncClient, headers: dict[str, str], *, bank: str, last4: str
) -> str:
    response = await client.post(
        "/v1/accounts",
        json={"bank": bank, "kind": "savings", "last4": last4},
        headers=headers,
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


async def test_auto_pair_entre_dos_cuentas_propias(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    account_a = await _create_account(client, user.headers, bank="bancolombia", last4="1234")
    account_b = await _create_account(client, user.headers, bank="nequi", last4="5678")

    debit = await _post_transaction(
        client,
        user.headers,
        amount="30000.00",
        direction="debit",
        account_id=account_a,
        occurred_at="2026-01-01T10:00:00+00:00",
    )
    credit = await _post_transaction(
        client,
        user.headers,
        amount="30000.00",
        direction="credit",
        account_id=account_b,
        occurred_at="2026-01-01T10:05:00+00:00",
    )

    assert credit["transfer_pair_id"] == debit["id"]
    assert credit["transfer_auto"] is True

    get_debit = await client.get(f"/v1/transactions/{debit['id']}", headers=user.headers)
    pair = get_debit.json()["pair"]
    assert pair is not None
    assert pair["id"] == credit["id"]

    return_to_expense = await client.patch(
        f"/v1/transactions/{debit['id']}", json={"kind": "expense"}, headers=user.headers
    )
    assert return_to_expense.status_code == 200
    assert return_to_expense.json()["kind"] == "expense"
    assert return_to_expense.json()["transfer_pair_id"] is None

    get_credit_after = await client.get(f"/v1/transactions/{credit['id']}", headers=user.headers)
    assert get_credit_after.json()["kind"] == "income"
    assert get_credit_after.json()["transfer_pair_id"] is None

    manual_pair = await client.post(
        f"/v1/transactions/{debit['id']}/transfer-pair",
        json={"pair_id": credit["id"]},
        headers=user.headers,
    )
    assert manual_pair.status_code == 200, manual_pair.text
    assert manual_pair.json()["transfer_auto"] is False
    assert manual_pair.json()["transfer_pair_id"] == credit["id"]


async def test_delete_transaccion_no_manual_es_403(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id)
    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    try:
        async with session_factory() as session:
            recorded = await record_captured_transaction(
                session,
                bus,
                SystemClock(),
                CapturedTransactionCommand(
                    user_id=user.id,
                    bank=Bank.BANCOLOMBIA,
                    amount=Decimal("20000.00"),
                    direction=Direction.DEBIT,
                    occurred_at=datetime(2026, 1, 5, tzinfo=UTC),
                    last4="1234",
                    merchant="Exito",
                    description=None,
                    suggested_category_slug=None,
                    parsed_by="rule:bancolombia:x",
                    confidence=0.8,
                    source=SourceInput(
                        channel=Channel.EMAIL,
                        raw_message_id=raw_message_id,
                        received_at=datetime.now(UTC),
                    ),
                ),
            )
    finally:
        await redis_client.aclose()

    response = await client.delete(
        f"/v1/transactions/{recorded.transaction.id}", headers=user.headers
    )
    assert response.status_code == 403
    assert response.json()["error"]["code"] == "forbidden"


async def test_delete_transaccion_manual_devuelve_204_y_luego_404(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    created = await _post_transaction(client, user.headers)

    delete_resp = await client.delete(f"/v1/transactions/{created['id']}", headers=user.headers)
    assert delete_resp.status_code == 204

    get_resp = await client.get(f"/v1/transactions/{created['id']}", headers=user.headers)
    assert get_resp.status_code == 404


async def test_post_manual_publica_evento_decodable_y_dedupe_hit_no_agrega_evento(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    settings: Settings,
    app: FastAPI,
) -> None:
    user = await user_factory()
    created = await _post_transaction(client, user.headers)

    registry = build_registry()
    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        entries = await redis_client.xrange("finanzia:events:ledger.TransactionCaptured")
        assert len(entries) == 1
        _, fields = entries[0]
        event = registry.decode(fields)
        assert isinstance(event, TransactionCaptured)
        assert str(event.transaction_id) == created["id"]

        bus = RedisStreamsEventBus(redis_client, registry)
        session_factory = app.state.session_factory
        raw_message_id = await insert_raw_message(session_factory, user_id=user.id)
        cmd = CapturedTransactionCommand(
            user_id=user.id,
            bank=Bank.NEQUI,
            amount=Decimal("5000.00"),
            direction=Direction.DEBIT,
            occurred_at=datetime(2026, 1, 10, tzinfo=UTC),
            last4="9999",
            merchant="Uber",
            description=None,
            suggested_category_slug=None,
            parsed_by="rule:nequi:x",
            confidence=0.7,
            source=SourceInput(
                channel=Channel.EMAIL, raw_message_id=raw_message_id, received_at=datetime.now(UTC)
            ),
        )

        async with session_factory() as session:
            first = await record_captured_transaction(session, bus, SystemClock(), cmd)
        assert first.created is True

        async with session_factory() as session:
            second = await record_captured_transaction(session, bus, SystemClock(), cmd)
        assert second.created is False

        entries_after = await redis_client.xrange("finanzia:events:ledger.TransactionCaptured")
        assert len(entries_after) == 2
    finally:
        await redis_client.aclose()


async def test_post_manual_con_event_bus_caido_devuelve_201_igual(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    app: FastAPI,
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    """El publish post-commit es fail-soft (review final, item C): la transaccion ya
    quedo confirmada, asi que un bus de eventos caido no debe convertirse en un 500.
    """
    user = await user_factory()

    class _FailingEventBus:
        async def publish(self, event: object) -> None:
            raise ConnectionError("redis unreachable")

    app.state.event_bus = _FailingEventBus()

    response = await client.post("/v1/transactions", json=_BASE_BODY, headers=user.headers)
    assert response.status_code == 201, response.text

    async with session_factory() as session:
        count = (
            await session.execute(
                text("SELECT count(*) FROM transactions WHERE user_id = :u"), {"u": str(user.id)}
            )
        ).scalar_one()
    assert count == 1


async def test_listado_trae_channels_email_y_notificacion_en_orden_estable(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
) -> None:
    """F4.2: una tx capturada por email y luego notificada trae `channels` ordenados
    segun el enum `Channel` (`email` antes que `notification`), sin importar el orden
    de llegada de las fuentes.
    """
    user = await user_factory()
    raw_message_email = await insert_raw_message(session_factory, user_id=user.id)
    raw_message_notification = await insert_raw_message(session_factory, user_id=user.id)
    redis_client = redis_asyncio.from_url(str(settings.redis_url))
    bus = RedisStreamsEventBus(redis_client, build_registry())
    occurred_at = datetime(2026, 1, 5, tzinfo=UTC)
    try:
        cmd = CapturedTransactionCommand(
            user_id=user.id,
            bank=Bank.BANCOLOMBIA,
            amount=Decimal("20000.00"),
            direction=Direction.DEBIT,
            occurred_at=occurred_at,
            last4="1234",
            merchant="Exito",
            description=None,
            suggested_category_slug=None,
            parsed_by="rule:bancolombia:x",
            confidence=0.8,
            source=SourceInput(
                channel=Channel.EMAIL,
                raw_message_id=raw_message_email,
                received_at=occurred_at,
            ),
        )
        async with session_factory() as session:
            await record_captured_transaction(session, bus, SystemClock(), cmd)

        later = occurred_at + timedelta(seconds=40)
        cmd_notification = replace(
            cmd,
            occurred_at=later,
            source=SourceInput(
                channel=Channel.NOTIFICATION,
                raw_message_id=raw_message_notification,
                received_at=later,
            ),
        )
        async with session_factory() as session:
            recorded = await record_captured_transaction(
                session, bus, SystemClock(), cmd_notification
            )
    finally:
        await redis_client.aclose()

    assert recorded.created is False  # misma captura: solo se adjunta la segunda fuente

    response = await client.get("/v1/transactions", headers=user.headers)
    assert response.status_code == 200, response.text
    items = response.json()["items"]
    assert len(items) == 1
    assert items[0]["channels"] == ["email", "notification"]
