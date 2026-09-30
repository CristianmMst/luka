"""Integracion de `DELETE /v1/me` y `GET /v1/me/export` (RF-11.2/11.3, spec 005 SS2)."""

from __future__ import annotations

from typing import TYPE_CHECKING

import pytest
from sqlalchemy import text
from support.gmail_connections import insert_gmail_connection

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable

    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
    from support.auth import AuthedUser

pytestmark = pytest.mark.integration

# Tablas con filas del usuario: despues del borrado ninguna debe tener nada.
_USER_TABLES = (
    "users WHERE id = :u",
    "refresh_tokens WHERE user_id = :u",
    "gmail_connections WHERE user_id = :u",
    "raw_messages WHERE user_id = :u",
    "linked_accounts WHERE user_id = :u",
    "categories WHERE user_id = :u",
    "transactions WHERE user_id = :u",
    "merchant_rules WHERE user_id = :u",
    "review_queue WHERE user_id = :u",
    "recurring_expenses WHERE user_id = :u",
    "recurring_occurrences WHERE user_id = :u",
    "device_tokens WHERE user_id = :u",
)


async def _seed(client: AsyncClient, user: AuthedUser) -> None:
    """Una cuenta, una categoria propia y un movimiento con ambas."""
    account = await client.post(
        "/v1/accounts",
        json={"bank": "nequi", "kind": "wallet", "alias": "Bolsillo"},
        headers=user.headers,
    )
    assert account.status_code == 201, account.text
    category = await client.post(
        "/v1/categories",
        json={"name": "Mascotas", "fiscal_tag": "no_deducible", "icon": "pets", "color": "#6B4C9A"},
        headers=user.headers,
    )
    assert category.status_code == 201, category.text
    tx = await client.post(
        "/v1/transactions",
        json={
            "amount": "45900.00",
            "direction": "debit",
            "occurred_at": "2026-09-26T15:00:00+00:00",
            "merchant": "Veterinaria",
            "account_id": account.json()["id"],
            "category_id": category.json()["id"],
        },
        headers=user.headers,
    )
    assert tx.status_code == 201, tx.text
    recurring = await client.post(
        "/v1/recurring-expenses",
        json={
            "name": "Veterinaria mensual",
            "merchant_keyword": "Veterinaria",
            "expected_amount": "45900",
            "day_of_month": 26,
        },
        headers=user.headers,
    )
    assert recurring.status_code == 201, recurring.text
    device = await client.put(
        "/v1/devices/push-token",
        json={"token": f"tok-{user.id}", "platform": "android"},
        headers=user.headers,
    )
    assert device.status_code == 204, device.text


async def test_exportar_trae_solo_los_datos_del_usuario(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    ana = await user_factory()
    bea = await user_factory(sub="sub-2", email="beatriz@example.com")
    await _seed(client, ana)
    await _seed(client, bea)

    response = await client.get("/v1/me/export", headers=ana.headers)

    assert response.status_code == 200
    assert "attachment" in response.headers["content-disposition"]
    body = response.json()
    assert body["format_version"] == 1
    assert body["profile"]["email"] == "ana@example.com"
    assert [a["alias"] for a in body["accounts"]] == ["Bolsillo"]
    assert [c["name"] for c in body["categories"]] == ["Mascotas"]
    (tx,) = body["transactions"]
    assert tx["amount"] == "45900.00"
    assert tx["category"] == "Mascotas"
    assert tx["sources"] == [{"channel": "manual", "received_at": tx["sources"][0]["received_at"]}]
    assert body["gmail"] == {"status": "none"}
    assert [r["name"] for r in body["recurring_expenses"]] == ["Veterinaria mensual"]
    (device,) = body["push_devices"]
    assert device["platform"] == "android"
    assert "token" not in device
    assert all(
        o["recurring_expense_id"] == body["recurring_expenses"][0]["id"]
        for o in body["recurring_occurrences"]
    )


async def test_exportar_sin_token_da_401(client: AsyncClient) -> None:
    assert (await client.get("/v1/me/export")).status_code == 401


async def test_borrar_la_cuenta_no_deja_nada_y_no_toca_a_otros(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    ana = await user_factory()
    bea = await user_factory(sub="sub-2", email="beatriz@example.com")
    await _seed(client, ana)
    await _seed(client, bea)
    await insert_gmail_connection(session_factory, user_id=ana.id)

    response = await client.delete("/v1/me", headers=ana.headers)
    assert response.status_code == 204

    async with session_factory() as session:
        for table in _USER_TABLES:
            count = (
                await session.execute(
                    text(f"SELECT count(*) FROM {table}"),  # noqa: S608 - tablas fijas del test
                    {"u": str(ana.id)},
                )
            ).scalar_one()
            assert count == 0, table
        bea_rows = (
            await session.execute(
                text("SELECT count(*) FROM transactions WHERE user_id = :u"), {"u": str(bea.id)}
            )
        ).scalar_one()
    assert bea_rows == 1

    # El refresh token quedo revocado (y borrado): no abre sesion.
    refreshed = await client.post("/v1/auth/refresh", json={"refresh_token": ana.refresh_token})
    assert refreshed.status_code == 401
    # Con el access JWT aun firmado, ya no hay usuario detras.
    assert (await client.get("/v1/me", headers=ana.headers)).status_code == 401
    assert (await client.delete("/v1/me", headers=ana.headers)).status_code == 401
