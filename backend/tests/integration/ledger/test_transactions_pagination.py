"""Tests de paginacion por cursor de `GET /v1/transactions` (spec 005 SS1/SS6, F1.7)."""

import asyncio
from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta

import pytest
from fastapi import FastAPI
from httpx import AsyncClient
from sqlalchemy import event
from support.auth import AuthedUser

pytestmark = pytest.mark.integration

_TOTAL = 120
_LIMIT = 50


async def _create_many(client: AsyncClient, headers: dict[str, str], count: int) -> None:
    base = datetime(2026, 1, 1, tzinfo=UTC)
    for i in range(count):
        occurred_at = (base + timedelta(minutes=i)).isoformat()
        response = await client.post(
            "/v1/transactions",
            json={"amount": "1000.00", "direction": "debit", "occurred_at": occurred_at},
            headers=headers,
        )
        assert response.status_code == 201, response.text


async def test_ciento_veinte_transacciones_limit_cincuenta_da_tres_paginas_sin_solapes(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    await _create_many(client, user.headers, _TOTAL)

    seen_ids: list[str] = []
    cursor: str | None = None
    pages = 0
    while True:
        params: dict[str, int | str] = {"limit": _LIMIT}
        if cursor is not None:
            params["cursor"] = cursor
        response = await client.get("/v1/transactions", params=params, headers=user.headers)
        assert response.status_code == 200, response.text
        body = response.json()
        seen_ids.extend(item["id"] for item in body["items"])
        pages += 1
        cursor = body["next_cursor"]
        if cursor is None:
            break

    assert pages == 3
    assert len(seen_ids) == _TOTAL
    assert len(set(seen_ids)) == _TOTAL

    # Orden esperado: `occurred_at DESC` (la primera pagina trae las mas recientes).
    first_page = await client.get(
        "/v1/transactions", params={"limit": _LIMIT}, headers=user.headers
    )
    items = first_page.json()["items"]
    occurred_ats = [item["occurred_at"] for item in items]
    assert occurred_ats == sorted(occurred_ats, reverse=True)

    # Controller ruling (fix round 1): el listado NO trae `sources`/`pair` (eso
    # solo se expone en `GET /transactions/{id}`, spec 005 SS6) pero si conserva
    # el resto de los campos de una transaccion, incl. `transfer_pair_id`.
    for item in items:
        assert "sources" not in item
        assert "pair" not in item
        assert "transfer_pair_id" in item
        assert "transfer_auto" in item


async def test_list_no_hace_n_mas_1_consultas(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]], app: FastAPI
) -> None:
    """El listado arma toda la pagina con una sola consulta al repositorio (RNF-3).

    Antes del fix round 1, cada fila recargaba fuentes/pareja via `GetTransaction`
    (N+1). Se cuentan los `SELECT` ejecutados en el engine sincrono subyacente
    durante una unica `GET /transactions?limit=50` sobre 120 filas.
    """
    user = await user_factory()
    await _create_many(client, user.headers, _TOTAL)

    statements: list[str] = []

    def _record(  # noqa: PLR0913, PLR0917 - firma fija del hook `before_cursor_execute`
        conn, cursor, statement, parameters, context, executemany
    ) -> None:
        statements.append(statement)

    engine = app.state.engine.sync_engine
    event.listen(engine, "before_cursor_execute", _record)
    try:
        response = await client.get(
            "/v1/transactions", params={"limit": _LIMIT}, headers=user.headers
        )
    finally:
        event.remove(engine, "before_cursor_execute", _record)

    assert response.status_code == 200, response.text
    assert len(response.json()["items"]) == _LIMIT

    select_statements = [s for s in statements if s.strip().upper().startswith("SELECT")]
    assert len(select_statements) <= 3, select_statements


async def test_updated_since_devuelve_solo_modificadas_en_orden_ascendente(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    await _create_many(client, user.headers, 5)
    listing = await client.get("/v1/transactions", headers=user.headers)
    ids = [item["id"] for item in listing.json()["items"]]
    assert len(ids) == 5

    await asyncio.sleep(0.05)
    checkpoint = datetime.now(UTC).isoformat()
    await asyncio.sleep(0.05)

    to_patch = ids[:2]
    for tx_id in to_patch:
        patch_resp = await client.patch(
            f"/v1/transactions/{tx_id}", json={"notes": "tocada"}, headers=user.headers
        )
        assert patch_resp.status_code == 200

    response = await client.get(
        "/v1/transactions", params={"updated_since": checkpoint}, headers=user.headers
    )
    assert response.status_code == 200
    body = response.json()
    returned_ids = [item["id"] for item in body["items"]]
    assert set(returned_ids) == set(to_patch)

    updated_ats = [item["updated_at"] for item in body["items"]]
    assert updated_ats == sorted(updated_ats)


async def test_cursor_de_occurred_usado_con_updated_since_es_400_field_cursor(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    await _create_many(client, user.headers, 3)

    occurred_listing = await client.get(
        "/v1/transactions", params={"limit": 1}, headers=user.headers
    )
    cursor = occurred_listing.json()["next_cursor"]
    assert cursor is not None

    response = await client.get(
        "/v1/transactions",
        params={"updated_since": "2026-01-01T00:00:00+00:00", "cursor": cursor},
        headers=user.headers,
    )
    assert response.status_code == 400
    assert response.json()["error"]["field"] == "cursor"


async def test_limit_201_es_400(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    response = await client.get("/v1/transactions", params={"limit": 201}, headers=user.headers)
    assert response.status_code == 400
