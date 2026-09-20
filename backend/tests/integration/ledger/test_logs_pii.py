"""Verifica que ledger no filtra datos personales/financieros en logs (spec 009 SS5)."""

from collections.abc import Awaitable, Callable

import pytest
import structlog.testing
from httpx import AsyncClient
from support.auth import AuthedUser

pytestmark = pytest.mark.integration

_AMOUNT = "873421.00"
_MERCHANT = "Super Secreto Comercio SAS"


async def test_post_y_get_transaccion_no_filtran_amount_merchant_ni_email(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory(sub="sub-pii", email="pii-secreto@example.com")

    with structlog.testing.capture_logs() as captured:
        create_resp = await client.post(
            "/v1/transactions",
            json={
                "amount": _AMOUNT,
                "direction": "debit",
                "occurred_at": "2026-01-01T12:00:00+00:00",
                "merchant": _MERCHANT,
            },
            headers=user.headers,
        )
        assert create_resp.status_code == 201, create_resp.text
        tx_id = create_resp.json()["id"]

        get_resp = await client.get(f"/v1/transactions/{tx_id}", headers=user.headers)
        assert get_resp.status_code == 200

    for entry in captured:
        rendered = repr(entry)
        assert _AMOUNT not in rendered
        assert _MERCHANT not in rendered
        assert "pii-secreto@example.com" not in rendered
