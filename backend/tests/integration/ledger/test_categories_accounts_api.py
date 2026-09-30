"""Tests de integracion de `/v1/categories` y `/v1/accounts` (spec 005 SS7, F1.7)."""

from collections.abc import Awaitable, Callable

import pytest
from httpx import AsyncClient
from support.auth import AuthedUser

from luka.modules.ledger.domain.system_categories import SIN_CATEGORIA_ID

pytestmark = pytest.mark.integration


async def test_categoria_duplicada_por_nombre_es_409(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    body = {"name": "Mascotas", "fiscal_tag": "no_deducible"}

    first = await client.post("/v1/categories", json=body, headers=user.headers)
    assert first.status_code == 201

    second = await client.post("/v1/categories", json=body, headers=user.headers)
    assert second.status_code == 409
    assert second.json()["error"]["code"] == "conflict"


async def test_cuenta_duplicada_por_bank_last4_es_409(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    body = {"bank": "bancolombia", "kind": "savings", "last4": "1111"}

    first = await client.post("/v1/accounts", json=body, headers=user.headers)
    assert first.status_code == 201

    second = await client.post("/v1/accounts", json=body, headers=user.headers)
    assert second.status_code == 409
    assert second.json()["error"]["code"] == "conflict"


async def test_last4_no_numerico_es_400_field_last4(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    response = await client.post(
        "/v1/accounts",
        json={"bank": "bancolombia", "kind": "savings", "last4": "12a4"},
        headers=user.headers,
    )
    assert response.status_code == 400
    assert response.json()["error"]["field"] == "last4"


async def test_delete_categoria_propia_reasigna_transacciones_a_sin_categoria(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    category_resp = await client.post(
        "/v1/categories",
        json={"name": "Viajes", "fiscal_tag": "no_deducible"},
        headers=user.headers,
    )
    category_id = category_resp.json()["id"]

    tx_resp = await client.post(
        "/v1/transactions",
        json={
            "amount": "10000.00",
            "direction": "debit",
            "occurred_at": "2026-01-01T12:00:00+00:00",
            "category_id": category_id,
        },
        headers=user.headers,
    )
    assert tx_resp.status_code == 201
    tx_id = tx_resp.json()["id"]

    delete_resp = await client.delete(f"/v1/categories/{category_id}", headers=user.headers)
    assert delete_resp.status_code == 204

    get_resp = await client.get(f"/v1/transactions/{tx_id}", headers=user.headers)
    assert get_resp.status_code == 200
    body = get_resp.json()
    assert body["category_id"] == str(SIN_CATEGORIA_ID)
    assert body["fiscal_tag"] == "no_deducible"


async def test_delete_categoria_en_transferencia_conserva_kind_y_fiscal_tag(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    """Invariante spec 004 SS2.5 (review final item A): al borrar la categoria de una
    transferencia, `category_id` se reasigna a `sin_categoria` pero `kind` y
    `fiscal_tag` deben seguir siendo `transfer`/`transferencia` (nunca `no_deducible`).
    """
    user = await user_factory()
    category_resp = await client.post(
        "/v1/categories",
        json={"name": "Ahorros", "fiscal_tag": "no_deducible"},
        headers=user.headers,
    )
    category_id = category_resp.json()["id"]

    tx_resp = await client.post(
        "/v1/transactions",
        json={
            "amount": "50000.00",
            "direction": "debit",
            "occurred_at": "2026-01-01T12:00:00+00:00",
            "category_id": category_id,
            "kind": "transfer",
        },
        headers=user.headers,
    )
    assert tx_resp.status_code == 201, tx_resp.text
    tx_id = tx_resp.json()["id"]
    assert tx_resp.json()["kind"] == "transfer"

    delete_resp = await client.delete(f"/v1/categories/{category_id}", headers=user.headers)
    assert delete_resp.status_code == 204

    get_resp = await client.get(f"/v1/transactions/{tx_id}", headers=user.headers)
    assert get_resp.status_code == 200
    body = get_resp.json()
    assert body["category_id"] == str(SIN_CATEGORIA_ID)
    assert body["kind"] == "transfer"
    assert body["fiscal_tag"] == "transferencia"


async def test_delete_cuenta_pone_null_account_id_en_transacciones(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    account_resp = await client.post(
        "/v1/accounts",
        json={"bank": "davivienda", "kind": "checking", "last4": "9012"},
        headers=user.headers,
    )
    account_id = account_resp.json()["id"]

    tx_resp = await client.post(
        "/v1/transactions",
        json={
            "amount": "10000.00",
            "direction": "debit",
            "occurred_at": "2026-01-01T12:00:00+00:00",
            "account_id": account_id,
        },
        headers=user.headers,
    )
    tx_id = tx_resp.json()["id"]

    delete_resp = await client.delete(f"/v1/accounts/{account_id}", headers=user.headers)
    assert delete_resp.status_code == 204

    get_resp = await client.get(f"/v1/transactions/{tx_id}", headers=user.headers)
    assert get_resp.json()["account_id"] is None


async def test_get_categories_devuelve_24_del_sistema_mas_las_propias(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    await client.post(
        "/v1/categories",
        json={"name": "Mi categoria", "fiscal_tag": "no_deducible"},
        headers=user.headers,
    )

    response = await client.get("/v1/categories", headers=user.headers)
    assert response.status_code == 200
    categories = response.json()
    system = [c for c in categories if c["is_system"]]
    own = [c for c in categories if not c["is_system"]]
    assert len(system) == 24
    assert len(own) == 1
    assert own[0]["name"] == "Mi categoria"


async def test_categoria_con_nombre_del_sistema_sin_importar_mayusculas_es_409(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    response = await client.post(
        "/v1/categories",
        json={"name": "DONACIONES", "fiscal_tag": "no_deducible"},
        headers=user.headers,
    )
    assert response.status_code == 409
    assert response.json()["error"]["field"] == "name"


async def test_patch_fiscal_tag_propaga_a_los_movimientos_y_toca_updated_at(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    category_id = (
        await client.post(
            "/v1/categories",
            json={"name": "Terapias", "fiscal_tag": "no_deducible"},
            headers=user.headers,
        )
    ).json()["id"]
    tx = (
        await client.post(
            "/v1/transactions",
            json={
                "amount": "90000.00",
                "direction": "debit",
                "occurred_at": "2026-01-01T12:00:00+00:00",
                "category_id": category_id,
            },
            headers=user.headers,
        )
    ).json()

    patch_resp = await client.patch(
        f"/v1/categories/{category_id}",
        json={"fiscal_tag": "deducible_salud"},
        headers=user.headers,
    )
    assert patch_resp.status_code == 200

    body = (await client.get(f"/v1/transactions/{tx['id']}", headers=user.headers)).json()
    assert body["fiscal_tag"] == "deducible_salud"
    assert body["updated_at"] > tx["updated_at"]
