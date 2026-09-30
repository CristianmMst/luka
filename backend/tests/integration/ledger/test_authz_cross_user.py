"""Tests de aislamiento entre usuarios (spec 009 SS4, SS8 item 3, F1.7).

Un recurso ajeno siempre responde 404 `not_found` (nunca 403), y la accion no
modifica nada; una categoria del sistema responde 403 `forbidden` (recurso visible
pero inmutable), tanto para el dueno como para cualquier otro usuario.
"""

from collections.abc import Awaitable, Callable

import pytest
from httpx import AsyncClient
from support.auth import AuthedUser

from luka.modules.ledger.domain.system_categories import SIN_CATEGORIA_ID

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


async def test_usuario_b_sobre_transaccion_de_a(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    second_user: AuthedUser,
) -> None:
    user_a = await user_factory()
    created = await _post_transaction(client, user_a.headers)
    tx_id = created["id"]

    get_resp = await client.get(f"/v1/transactions/{tx_id}", headers=second_user.headers)
    assert get_resp.status_code == 404
    assert get_resp.json()["error"]["code"] == "not_found"

    patch_resp = await client.patch(
        f"/v1/transactions/{tx_id}", json={"notes": "hackeado"}, headers=second_user.headers
    )
    assert patch_resp.status_code == 404

    delete_resp = await client.delete(f"/v1/transactions/{tx_id}", headers=second_user.headers)
    assert delete_resp.status_code == 404

    other = await _post_transaction(
        client, second_user.headers, direction="credit", occurred_at="2026-01-01T10:05:00+00:00"
    )
    transfer_resp = await client.post(
        f"/v1/transactions/{tx_id}/transfer-pair",
        json={"pair_id": other["id"]},
        headers=second_user.headers,
    )
    assert transfer_resp.status_code == 404

    unset_resp = await client.delete(
        f"/v1/transactions/{tx_id}/transfer-pair", headers=second_user.headers
    )
    assert unset_resp.status_code == 404

    still_there = await client.get(f"/v1/transactions/{tx_id}", headers=user_a.headers)
    assert still_there.status_code == 200
    assert still_there.json()["notes"] is None


async def test_usuario_b_sobre_categoria_de_a(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    second_user: AuthedUser,
) -> None:
    user_a = await user_factory()
    category_resp = await client.post(
        "/v1/categories",
        json={"name": "Categoria de A", "fiscal_tag": "no_deducible"},
        headers=user_a.headers,
    )
    assert category_resp.status_code == 201
    category_id = category_resp.json()["id"]

    get_list = await client.get("/v1/categories", headers=second_user.headers)
    assert category_id not in {c["id"] for c in get_list.json()}

    patch_resp = await client.patch(
        f"/v1/categories/{category_id}",
        json={"name": "Hackeada"},
        headers=second_user.headers,
    )
    assert patch_resp.status_code == 404

    delete_resp = await client.delete(f"/v1/categories/{category_id}", headers=second_user.headers)
    assert delete_resp.status_code == 404

    still_there = await client.get("/v1/categories", headers=user_a.headers)
    names = {c["id"]: c["name"] for c in still_there.json()}
    assert names[category_id] == "Categoria de A"


async def test_usuario_b_sobre_cuenta_de_a(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    second_user: AuthedUser,
) -> None:
    user_a = await user_factory()
    account_resp = await client.post(
        "/v1/accounts",
        json={"bank": "bancolombia", "kind": "savings", "last4": "4321"},
        headers=user_a.headers,
    )
    assert account_resp.status_code == 201
    account_id = account_resp.json()["id"]

    patch_resp = await client.patch(
        f"/v1/accounts/{account_id}", json={"alias": "hackeada"}, headers=second_user.headers
    )
    assert patch_resp.status_code == 404

    delete_resp = await client.delete(f"/v1/accounts/{account_id}", headers=second_user.headers)
    assert delete_resp.status_code == 404

    listing = await client.get("/v1/accounts", headers=user_a.headers)
    assert any(a["id"] == account_id for a in listing.json())


async def test_categoria_del_sistema_patch_y_delete_son_403(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    system_category_id = str(SIN_CATEGORIA_ID)

    patch_resp = await client.patch(
        f"/v1/categories/{system_category_id}",
        json={"name": "No deberia poder"},
        headers=user.headers,
    )
    assert patch_resp.status_code == 403
    assert patch_resp.json()["error"]["code"] == "forbidden"

    delete_resp = await client.delete(f"/v1/categories/{system_category_id}", headers=user.headers)
    assert delete_resp.status_code == 403
    assert delete_resp.json()["error"]["code"] == "forbidden"


async def test_usuario_b_no_puede_usar_la_categoria_de_a_en_un_movimiento(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    second_user: AuthedUser,
) -> None:
    user_a = await user_factory()
    category_id = (
        await client.post(
            "/v1/categories",
            json={"name": "Solo de A", "fiscal_tag": "no_deducible"},
            headers=user_a.headers,
        )
    ).json()["id"]

    response = await client.post(
        "/v1/transactions",
        json={
            "amount": "5000.00",
            "direction": "debit",
            "occurred_at": "2026-01-01T12:00:00+00:00",
            "category_id": category_id,
        },
        headers=second_user.headers,
    )
    assert response.status_code == 404
