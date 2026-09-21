"""Tests de integracion HTTP de `GET /v1/config/capture` (spec 006 §3.1, D6)."""

from collections.abc import Awaitable, Callable

import pytest
from httpx import AsyncClient
from support.auth import AuthedUser

pytestmark = pytest.mark.integration


async def test_sin_token_responde_401(client: AsyncClient) -> None:
    response = await client.get("/v1/config/capture")
    assert response.status_code == 401


async def test_config_capture_incluye_apps_y_remitentes_reales(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()

    response = await client.get("/v1/config/capture", headers=user.headers)

    assert response.status_code == 200
    body = response.json()
    assert body["version"] == 1
    assert "com.bancolombia.app" in body["banking_apps"]
    assert body["messages_apps"]
    assert "com.google.android.apps.messaging" in body["messages_apps"]
    assert body["sms_sender_patterns"]
    assert (
        "alertasynotificaciones@an.notificacionesbancolombia.com"
        in body["email_senders"]["bancolombia"]
    )
    assert response.headers["cache-control"] == "private, max-age=3600"
