"""Tests de integracion HTTP de `POST /v1/ingest/notifications` (spec 006 §3.2,
005 §5 enmendado, 009 §1/§4, AC-3.3, P1/P8).
"""

import hashlib
from collections.abc import Awaitable, Callable
from datetime import UTC, datetime
from uuid import uuid4

import pytest
import redis.asyncio as redis_asyncio
import structlog.testing
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser

from finanzia.events_registry import build_registry
from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration

_POSTED_AT = datetime(2026, 5, 1, 16, 0, tzinfo=UTC).isoformat()
_BANCOLOMBIA_TEXT = (
    "Bancolombia: Compraste $176.824,00 en CARBON Y XILVESTRE T con tu T.Deb "
    "*1234, el 01/05/2026 a las 16:00."
)


def _hash(seed: str) -> str:
    return hashlib.sha256(seed.encode()).hexdigest()


def _item(  # noqa: PLR0913 - helper de test, un parametro por campo del schema
    *,
    package: str,
    channel: str = "notification",
    text_: str = _BANCOLOMBIA_TEXT,
    client_hash: str,
    title: str | None = None,
    posted_at: str = _POSTED_AT,
) -> dict[str, object]:
    return {
        "package": package,
        "channel": channel,
        "posted_at": posted_at,
        "title": title,
        "text": text_,
        "client_hash": client_hash,
    }


async def _row_count(session_factory: async_sessionmaker[AsyncSession], user_id: object) -> int:
    async with session_factory() as session:
        return (
            await session.execute(
                text("SELECT count(*) FROM raw_messages WHERE user_id = :u"), {"u": user_id}
            )
        ).scalar_one()


async def _rows(
    session_factory: async_sessionmaker[AsyncSession], user_id: object
) -> list[dict[str, object]]:
    async with session_factory() as session:
        result = await session.execute(
            text("SELECT bank, body FROM raw_messages WHERE user_id = :u ORDER BY created_at"),
            {"u": user_id},
        )
        return [dict(row._mapping) for row in result]


async def _stream_entries(settings: Settings, event_type: str) -> list[object]:
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        entries = await client.xrange(f"finanzia:events:{event_type}")
        registry = build_registry()
        return [registry.decode(fields) for _, fields in entries]
    finally:
        await client.aclose()


async def test_sin_token_responde_401(client: AsyncClient) -> None:
    body = {"items": [_item(package="com.bancolombia.app", client_hash=_hash("no-auth"))]}
    response = await client.post("/v1/ingest/notifications", json=body)
    assert response.status_code == 401


async def test_batch_bancolombia_y_paquete_no_soportado(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    hash1, hash2, hash3 = _hash("b1"), _hash("b2"), _hash("whatsapp")
    body = {
        "items": [
            _item(package="com.bancolombia.app", client_hash=hash1),
            _item(package="com.bancolombia.app", client_hash=hash2, text_=_BANCOLOMBIA_TEXT + " "),
            _item(package="com.whatsapp", client_hash=hash3, text_="mensaje cualquiera"),
        ]
    }

    response = await client.post("/v1/ingest/notifications", headers=user.headers, json=body)

    assert response.status_code == 200
    assert response.json() == {"accepted": 2, "duplicates": 0, "discarded": 1}
    assert await _row_count(session_factory, user.id) == 2
    rows = await _rows(session_factory, user.id)
    assert all(row["bank"] == "bancolombia" for row in rows)
    assert all(row["body"] in (_BANCOLOMBIA_TEXT, _BANCOLOMBIA_TEXT + " ") for row in rows)

    # Repetir el mismo batch: idempotencia por indice (client_hash = external_id).
    repeat = await client.post("/v1/ingest/notifications", headers=user.headers, json=body)
    assert repeat.status_code == 200
    assert repeat.json() == {"accepted": 0, "duplicates": 2, "discarded": 1}
    assert await _row_count(session_factory, user.id) == 2


async def test_sms_notification_bancolombia_aceptada_por_titulo(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    body = {
        "items": [
            _item(
                package="com.google.android.apps.messaging",
                channel="sms_notification",
                title="Bancolombia",
                text_="Compraste $10.000 con tu tarjeta",
                client_hash=_hash("sms-bancolombia"),
            )
        ]
    }

    response = await client.post("/v1/ingest/notifications", headers=user.headers, json=body)

    assert response.status_code == 200
    assert response.json() == {"accepted": 1, "duplicates": 0, "discarded": 0}
    rows = await _rows(session_factory, user.id)
    assert len(rows) == 1
    assert rows[0]["bank"] == "bancolombia"


async def test_sms_notification_sin_remitente_reconocido_se_descarta_sin_loguear_el_texto(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    secret_text = "texto secreto de Mama que nunca debe aparecer en logs ni filas"
    body = {
        "items": [
            _item(
                package="com.google.android.apps.messaging",
                channel="sms_notification",
                title="Mamá",
                text_=secret_text,
                client_hash=_hash("sms-mama"),
            )
        ]
    }

    with structlog.testing.capture_logs() as captured:
        response = await client.post("/v1/ingest/notifications", headers=user.headers, json=body)

    assert response.status_code == 200
    assert response.json() == {"accepted": 0, "duplicates": 0, "discarded": 1}
    assert await _row_count(session_factory, user.id) == 0

    for entry in captured:
        rendered = repr(entry)
        assert secret_text not in rendered
        assert "Mamá" not in rendered


async def test_client_hash_invalido_responde_400_con_field_del_item(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    body = {"items": [_item(package="com.bancolombia.app", client_hash="no-es-un-hash-valido")]}

    response = await client.post("/v1/ingest/notifications", headers=user.headers, json=body)

    assert response.status_code == 400
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert payload["error"]["field"].startswith("items.0.client_hash")


async def test_posted_at_naive_responde_400(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    body = {
        "items": [
            _item(
                package="com.bancolombia.app",
                client_hash=_hash("naive"),
                posted_at="2026-05-01T16:00:00",
            )
        ]
    }

    response = await client.post("/v1/ingest/notifications", headers=user.headers, json=body)

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "validation_error"


async def test_text_demasiado_largo_responde_400(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    body = {
        "items": [
            _item(
                package="com.bancolombia.app",
                client_hash=_hash("largo"),
                text_="a" * 65537,
            )
        ]
    }

    response = await client.post("/v1/ingest/notifications", headers=user.headers, json=body)

    assert response.status_code == 400


async def test_items_vacio_responde_400(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    response = await client.post(
        "/v1/ingest/notifications", headers=user.headers, json={"items": []}
    )
    assert response.status_code == 400


async def test_51_items_responde_400(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    items = [
        _item(package="com.bancolombia.app", client_hash=_hash(f"item-{i}")) for i in range(51)
    ]
    response = await client.post(
        "/v1/ingest/notifications", headers=user.headers, json={"items": items}
    )
    assert response.status_code == 400


async def test_campo_extra_desconocido_responde_400(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    item = _item(package="com.bancolombia.app", client_hash=_hash("extra"))
    item["unexpected_field"] = "x"
    response = await client.post(
        "/v1/ingest/notifications", headers=user.headers, json={"items": [item]}
    )
    assert response.status_code == 400


async def test_idempotency_key_repetida_replica_la_respuesta(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    body = {"items": [_item(package="com.bancolombia.app", client_hash=_hash("idem-1"))]}
    headers = {**user.headers, "Idempotency-Key": str(uuid4())}

    first = await client.post("/v1/ingest/notifications", headers=headers, json=body)
    assert first.status_code == 200
    assert first.json() == {"accepted": 1, "duplicates": 0, "discarded": 0}
    assert "idempotency-replayed" not in first.headers

    second = await client.post("/v1/ingest/notifications", headers=headers, json=body)
    assert second.status_code == 200
    assert second.json() == first.json()
    assert second.headers["idempotency-replayed"] == "true"

    # La replica no re-ejecuto el batch: sigue habiendo una unica fila.
    assert await _row_count(session_factory, user.id) == 1


async def test_cada_item_aceptado_publica_raw_message_received(
    client: AsyncClient,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    redis_clean: None,
) -> None:
    del redis_clean
    user = await user_factory()
    hash1, hash2 = _hash("evt-1"), _hash("evt-2")
    body = {
        "items": [
            _item(package="com.bancolombia.app", client_hash=hash1),
            _item(package="com.bancolombia.app", client_hash=hash2, text_=_BANCOLOMBIA_TEXT + "!"),
        ]
    }

    response = await client.post("/v1/ingest/notifications", headers=user.headers, json=body)
    assert response.status_code == 200
    assert response.json()["accepted"] == 2

    entries = [
        e
        for e in await _stream_entries(settings, "ingestion.RawMessageReceived")
        if e.user_id == user.id  # type: ignore[attr-defined]
    ]
    assert len(entries) == 2


async def test_batches_de_usuarios_distintos_no_se_mezclan(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
    second_user: AuthedUser,
) -> None:
    user_a = await user_factory()
    shared_hash = _hash("cross-user-same-hash")

    body = {"items": [_item(package="com.bancolombia.app", client_hash=shared_hash)]}

    response_a = await client.post("/v1/ingest/notifications", headers=user_a.headers, json=body)
    response_b = await client.post(
        "/v1/ingest/notifications", headers=second_user.headers, json=body
    )

    assert response_a.status_code == 200
    assert response_b.status_code == 200
    # Mismo client_hash, usuarios distintos: ambos se aceptan (la unicidad es por
    # `(user_id, channel, external_id)`), sin duplicados cruzados.
    assert response_a.json() == {"accepted": 1, "duplicates": 0, "discarded": 0}
    assert response_b.json() == {"accepted": 1, "duplicates": 0, "discarded": 0}
    assert await _row_count(session_factory, user_a.id) == 1
    assert await _row_count(session_factory, second_user.id) == 1
