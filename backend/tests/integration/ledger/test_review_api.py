"""Tests de integracion de `/v1/review` (spec 005 SS7, D1, F2.5/F2.6)."""

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime
from uuid import UUID, uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.raw_messages import insert_raw_message

from finanzia.modules.ledger.infrastructure.consumers import make_parse_failed_handler
from finanzia.modules.parsing.domain.enums import ParseFailureReason
from finanzia.modules.parsing.events import ParseFailed
from finanzia.shared.clock import SystemClock

pytestmark = pytest.mark.integration

_BODY = (
    "Bancolombia: Compraste $45.900 en OXXO CALLE 59 con tu T.Deb *1234, el 19/09/2026 a las 21:52."
)


async def _enqueue_via_parse_failed(
    session_factory: async_sessionmaker[AsyncSession],
    *,
    user_id: UUID,
    raw_message_id: UUID,
    reason: ParseFailureReason = ParseFailureReason.LLM_LOW_CONFIDENCE,
    received_at: datetime | None = None,
) -> None:
    """Encola `raw_message_id` invocando el handler real de `parsing.ParseFailed`."""
    handler = make_parse_failed_handler(session_factory=session_factory, clock=SystemClock())
    event = ParseFailed(
        event_id=uuid4(),
        occurred_at=datetime.now(UTC),
        raw_message_id=raw_message_id,
        user_id=user_id,
        channel="email",
        bank="bancolombia",
        reason=reason,
        partial_extract={"amount": "45900"},
        received_at=received_at or datetime.now(UTC),
    )
    await handler(event)


async def test_parse_failed_handler_crea_fila_en_review_queue(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id, body=_BODY)

    await _enqueue_via_parse_failed(session_factory, user_id=user.id, raw_message_id=raw_message_id)

    async with session_factory() as session:
        row = (
            await session.execute(
                text("SELECT reason, resolved_at FROM review_queue WHERE raw_message_id = :id"),
                {"id": str(raw_message_id)},
            )
        ).one()
    assert row.reason == "llm_low_confidence"
    assert row.resolved_at is None


async def test_get_review_devuelve_text_reason_y_partial_extract(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id, body=_BODY)
    await _enqueue_via_parse_failed(session_factory, user_id=user.id, raw_message_id=raw_message_id)

    response = await client.get("/v1/review", headers=user.headers)
    assert response.status_code == 200, response.text
    body = response.json()
    assert len(body["items"]) == 1
    item = body["items"][0]
    assert item["raw_message_id"] == str(raw_message_id)
    assert item["text"] == _BODY
    assert item["reason"] == "llm_low_confidence"
    assert item["partial_extract"] == {"amount": "45900"}
    assert item["channel"] == "email"
    assert item["bank"] == "bancolombia"


def _convert_body(**overrides: object) -> dict[str, object]:
    base: dict[str, object] = {
        "amount": "45900.00",
        "direction": "debit",
        "occurred_at": "2026-09-19T21:52:00-05:00",
        "merchant": "OXXO CALLE 59",
    }
    return {**base, **overrides}


async def test_convert_via_api_crea_transaccion_y_marca_reviewed(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id, body=_BODY)
    await _enqueue_via_parse_failed(session_factory, user_id=user.id, raw_message_id=raw_message_id)

    response = await client.post(
        f"/v1/review/{raw_message_id}/convert", json=_convert_body(), headers=user.headers
    )
    assert response.status_code == 201, response.text
    tx = response.json()
    assert tx["parsed_by"] == "manual"

    get_resp = await client.get(f"/v1/transactions/{tx['id']}", headers=user.headers)
    assert get_resp.status_code == 200
    sources = get_resp.json()["sources"]
    assert len(sources) == 1
    assert sources[0]["raw_message_id"] == str(raw_message_id)
    assert sources[0]["channel"] == "email"

    async with session_factory() as session:
        status_row = (
            await session.execute(
                text("SELECT status FROM raw_messages WHERE id = :id"), {"id": str(raw_message_id)}
            )
        ).scalar_one()
    assert status_row == "reviewed"

    listing = await client.get("/v1/review", headers=user.headers)
    assert listing.json()["items"] == []

    second = await client.post(
        f"/v1/review/{raw_message_id}/convert", json=_convert_body(), headers=user.headers
    )
    assert second.status_code == 409


async def test_convert_item_inexistente_es_404(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    response = await client.post(
        f"/v1/review/{uuid4()}/convert", json=_convert_body(), headers=user.headers
    )
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


async def test_discard_via_api_resuelve_y_marca_discarded(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id, body=_BODY)
    await _enqueue_via_parse_failed(session_factory, user_id=user.id, raw_message_id=raw_message_id)

    response = await client.post(f"/v1/review/{raw_message_id}/discard", headers=user.headers)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["raw_message_id"] == str(raw_message_id)
    assert body["resolution"] == "discarded"
    assert body["resolved_at"] is not None

    async with session_factory() as session:
        status_row = (
            await session.execute(
                text("SELECT status FROM raw_messages WHERE id = :id"), {"id": str(raw_message_id)}
            )
        ).scalar_one()
    assert status_row == "discarded"

    listing = await client.get("/v1/review", headers=user.headers)
    assert listing.json()["items"] == []


async def test_usuario_b_sobre_item_de_a_es_404_y_lista_vacia(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
    second_user: AuthedUser,
) -> None:
    user_a = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user_a.id, body=_BODY)
    await _enqueue_via_parse_failed(
        session_factory, user_id=user_a.id, raw_message_id=raw_message_id
    )

    empty_list = await client.get("/v1/review", headers=second_user.headers)
    assert empty_list.status_code == 200
    assert empty_list.json()["items"] == []

    convert_resp = await client.post(
        f"/v1/review/{raw_message_id}/convert", json=_convert_body(), headers=second_user.headers
    )
    assert convert_resp.status_code == 404

    discard_resp = await client.post(
        f"/v1/review/{raw_message_id}/discard", headers=second_user.headers
    )
    assert discard_resp.status_code == 404

    still_open = await client.get("/v1/review", headers=user_a.headers)
    assert len(still_open.json()["items"]) == 1


async def test_paginacion_limit_2_sobre_5_items(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_ids = []
    for i in range(5):
        raw_id = await insert_raw_message(
            session_factory, user_id=user.id, external_id=f"review-page-{i}", body=_BODY
        )
        await _enqueue_via_parse_failed(session_factory, user_id=user.id, raw_message_id=raw_id)
        raw_ids.append(raw_id)

    seen: list[str] = []
    cursor: str | None = None
    pages = 0
    while True:
        params: dict[str, int | str] = {"limit": 2}
        if cursor is not None:
            params["cursor"] = cursor
        response = await client.get("/v1/review", params=params, headers=user.headers)
        assert response.status_code == 200, response.text
        body = response.json()
        seen.extend(item["raw_message_id"] for item in body["items"])
        pages += 1
        cursor = body["next_cursor"]
        if cursor is None:
            break
        assert pages <= 10

    assert pages == 3
    assert len(seen) == len(set(seen)) == 5
    assert {str(r) for r in raw_ids} == set(seen)


async def test_reentrega_de_parse_failed_no_duplica_fila(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id, body=_BODY)

    await _enqueue_via_parse_failed(session_factory, user_id=user.id, raw_message_id=raw_message_id)
    await _enqueue_via_parse_failed(session_factory, user_id=user.id, raw_message_id=raw_message_id)

    async with session_factory() as session:
        count = (
            await session.execute(
                text("SELECT count(*) FROM review_queue WHERE raw_message_id = :id"),
                {"id": str(raw_message_id)},
            )
        ).scalar_one()
    assert count == 1
