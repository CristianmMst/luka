"""Tests de integracion HTTP de la regla `ingest_user` (spec 009 §4, Task 5/F4.3).

Espeja `tests/integration/shared/test_rate_limit_api.py`: cada test construye su
propia app via `settings.model_copy(update={...})` con un limite bajo a proposito.
"""

import hashlib
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

import pytest
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient
from support.google_stub import create_test_app

from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration


@pytest.fixture(autouse=True)
async def _redis_limpio(redis_clean: None) -> None:
    """Evita que las claves `rl:*` se filtren entre tests de este modulo.

    `_tablas_limpias` (tablas de usuario) ya es autouse en `conftest.py` de este
    paquete.
    """
    del redis_clean


@asynccontextmanager
async def _client_for(settings: Settings) -> AsyncGenerator[AsyncClient, None]:
    app = create_test_app(settings)
    async with LifespanManager(app):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac


def _batch(seed: str) -> dict[str, object]:
    client_hash = hashlib.sha256(seed.encode()).hexdigest()
    return {
        "items": [
            {
                "package": "com.bancolombia.app",
                "channel": "notification",
                "posted_at": "2026-05-01T16:00:00-05:00",
                "title": None,
                "text": (
                    "Bancolombia: Compraste $1.00 en X con tu T.Deb *1234, "
                    "el 01/05/2026 a las 16:00."
                ),
                "client_hash": client_hash,
            }
        ]
    }


async def test_tercera_llamada_a_ingest_responde_429_pero_me_sigue_funcionando(
    settings: Settings,
) -> None:
    custom_settings = settings.model_copy(update={"rate_limit_ingest_per_minute": 2})
    async with _client_for(custom_settings) as client:
        login_response = await client.post(
            "/v1/auth/google", json={"id_token": "stub:sub-ingest-rl-1:ingestrl1@example.com"}
        )
        assert login_response.status_code == 200
        headers = {"Authorization": f"Bearer {login_response.json()['access_token']}"}

        first = await client.post("/v1/ingest/notifications", headers=headers, json=_batch("rl-1"))
        second = await client.post("/v1/ingest/notifications", headers=headers, json=_batch("rl-2"))
        third = await client.post("/v1/ingest/notifications", headers=headers, json=_batch("rl-3"))

        assert first.status_code == 200
        assert second.status_code == 200
        assert third.status_code == 429
        assert third.headers["retry-after"] == "60"
        assert third.json()["error"]["code"] == "rate_limited"

        # La regla `ingest_user` es independiente de la global: `/v1/me` sigue OK.
        me_response = await client.get("/v1/me", headers=headers)
        assert me_response.status_code == 200


async def test_un_segundo_usuario_no_se_ve_afectado_por_el_limite_del_primero(
    settings: Settings,
) -> None:
    custom_settings = settings.model_copy(update={"rate_limit_ingest_per_minute": 1})
    async with _client_for(custom_settings) as client:
        login_a = await client.post(
            "/v1/auth/google", json={"id_token": "stub:sub-ingest-rl-a:ingestrla@example.com"}
        )
        headers_a = {"Authorization": f"Bearer {login_a.json()['access_token']}"}
        login_b = await client.post(
            "/v1/auth/google", json={"id_token": "stub:sub-ingest-rl-b:ingestrlb@example.com"}
        )
        headers_b = {"Authorization": f"Bearer {login_b.json()['access_token']}"}

        first_a = await client.post(
            "/v1/ingest/notifications", headers=headers_a, json=_batch("rl-a-1")
        )
        second_a = await client.post(
            "/v1/ingest/notifications", headers=headers_a, json=_batch("rl-a-2")
        )
        first_b = await client.post(
            "/v1/ingest/notifications", headers=headers_b, json=_batch("rl-b-1")
        )

        assert first_a.status_code == 200
        assert second_a.status_code == 429
        assert first_b.status_code == 200
