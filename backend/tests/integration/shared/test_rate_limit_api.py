"""Tests de integracion HTTP del rate limiting (spec 009 SS4, F1.4).

Cada test construye su propia app via `settings.model_copy(update={...})` con
limites bajos a proposito, para no depender de (ni afectar a) la `app`/`client`
compartidas del resto de la suite (esas usan limites altos, ver `conftest.py`).
"""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

import pytest
import structlog
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient

from finanzia.app import create_app
from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration


@pytest.fixture(autouse=True)
async def _redis_limpio(redis_clean: None) -> None:
    """Evita que las claves `rl:*` se filtren entre tests de este modulo."""
    del redis_clean


@pytest.fixture(autouse=True)
async def _tablas_limpias(db_clean: None) -> None:
    """Los tests que loguean usuarios (regla `user`) arrancan con tablas vacias."""
    del db_clean


@asynccontextmanager
async def _client_for(settings: Settings) -> AsyncGenerator[AsyncClient, None]:
    app = create_app(settings)
    async with LifespanManager(app):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac


async def test_limite_por_ip_en_auth_rechaza_la_cuarta_llamada(settings: Settings) -> None:
    custom_settings = settings.model_copy(update={"rate_limit_auth_per_minute": 3})
    async with _client_for(custom_settings) as client:
        for _ in range(3):
            response = await client.post("/v1/auth/google", json={"id_token": "short"})
            assert response.status_code == 400

        response = await client.post("/v1/auth/google", json={"id_token": "short"})

    assert response.status_code == 429
    assert response.headers["retry-after"] == "60"
    assert response.json()["error"]["code"] == "rate_limited"


async def test_health_nunca_se_limita(settings: Settings) -> None:
    custom_settings = settings.model_copy(update={"rate_limit_auth_per_minute": 3})
    async with _client_for(custom_settings) as client:
        for _ in range(20):
            response = await client.get("/health")
            assert response.status_code == 200


async def test_limite_global_por_usuario_en_me(settings: Settings) -> None:
    custom_settings = settings.model_copy(update={"rate_limit_user_per_minute": 2})
    async with _client_for(custom_settings) as client:
        login_response = await client.post(
            "/v1/auth/google", json={"id_token": "fake:sub-rl-1:rl1@example.com"}
        )
        assert login_response.status_code == 200
        headers = {"Authorization": f"Bearer {login_response.json()['access_token']}"}

        # El login no lleva bearer: la regla `user` no aplica y no consume el cupo.
        first_me = await client.get("/v1/me", headers=headers)
        assert first_me.status_code == 200

        second_me = await client.get("/v1/me", headers=headers)
        assert second_me.status_code == 200

        third_me = await client.get("/v1/me", headers=headers)

    assert third_me.status_code == 429
    assert third_me.headers["retry-after"] == "60"
    assert third_me.json()["error"]["code"] == "rate_limited"


async def test_llamadas_no_autenticadas_a_me_no_consumen_el_cupo_de_usuario(
    settings: Settings,
) -> None:
    custom_settings = settings.model_copy(update={"rate_limit_user_per_minute": 1})
    async with _client_for(custom_settings) as client:
        for _ in range(5):
            response = await client.get("/v1/me")
            assert response.status_code == 401

        login_response = await client.post(
            "/v1/auth/google", json={"id_token": "fake:sub-rl-2:rl2@example.com"}
        )
        headers = {"Authorization": f"Bearer {login_response.json()['access_token']}"}

        # El cupo (limite=1) sigue intacto: las llamadas no autenticadas no cuentan.
        first_me = await client.get("/v1/me", headers=headers)

    assert first_me.status_code == 200


async def test_xff_respetado_solo_con_trust_proxy_headers(settings: Settings) -> None:
    custom_settings = settings.model_copy(
        update={"rate_limit_auth_per_minute": 1, "trust_proxy_headers": True}
    )
    async with _client_for(custom_settings) as client:
        first = await client.post(
            "/v1/auth/google",
            json={"id_token": "short"},
            headers={"X-Forwarded-For": "1.1.1.1"},
        )
        second = await client.post(
            "/v1/auth/google",
            json={"id_token": "short"},
            headers={"X-Forwarded-For": "2.2.2.2"},
        )
        third = await client.post(
            "/v1/auth/google",
            json={"id_token": "short"},
            headers={"X-Forwarded-For": "1.1.1.1"},
        )

    assert first.status_code == 400
    assert second.status_code == 400
    assert third.status_code == 429


async def test_xff_usa_el_ultimo_valor_no_el_primero(settings: Settings) -> None:
    """El hop de la derecha lo agrega el proxy de confianza; la izquierda la controla
    el cliente (controller ruling, spec 009 SS4). Dos requests con el mismo valor mas
    a la derecha comparten cupo aunque el valor mas a la izquierda (spoofeado por el
    cliente) sea distinto.
    """
    custom_settings = settings.model_copy(
        update={"rate_limit_auth_per_minute": 1, "trust_proxy_headers": True}
    )
    async with _client_for(custom_settings) as client:
        first = await client.post(
            "/v1/auth/google",
            json={"id_token": "short"},
            headers={"X-Forwarded-For": "9.9.9.9, 1.1.1.1"},
        )
        # Mismo valor derecho (1.1.1.1) con un valor izquierdo distinto/spoofeado:
        # debe compartir el mismo cupo que la request anterior.
        second = await client.post(
            "/v1/auth/google",
            json={"id_token": "short"},
            headers={"X-Forwarded-For": "666.666.666.666, 1.1.1.1"},
        )

    assert first.status_code == 400
    assert second.status_code == 429


async def test_xff_valores_derechos_distintos_no_comparten_cupo(settings: Settings) -> None:
    custom_settings = settings.model_copy(
        update={"rate_limit_auth_per_minute": 1, "trust_proxy_headers": True}
    )
    async with _client_for(custom_settings) as client:
        first = await client.post(
            "/v1/auth/google",
            json={"id_token": "short"},
            headers={"X-Forwarded-For": "9.9.9.9, 1.1.1.1"},
        )
        # Mismo valor izquierdo (spoofeado), valor derecho distinto: cupo distinto.
        second = await client.post(
            "/v1/auth/google",
            json={"id_token": "short"},
            headers={"X-Forwarded-For": "9.9.9.9, 2.2.2.2"},
        )

    assert first.status_code == 400
    assert second.status_code == 400


async def test_xff_ignorado_sin_trust_proxy_headers(settings: Settings) -> None:
    custom_settings = settings.model_copy(
        update={"rate_limit_auth_per_minute": 1, "trust_proxy_headers": False}
    )
    async with _client_for(custom_settings) as client:
        first = await client.post(
            "/v1/auth/google",
            json={"id_token": "short"},
            headers={"X-Forwarded-For": "1.1.1.1"},
        )
        second = await client.post(
            "/v1/auth/google",
            json={"id_token": "short"},
            headers={"X-Forwarded-For": "2.2.2.2"},
        )

    assert first.status_code == 400
    assert second.status_code == 429


async def test_falla_abierto_si_redis_no_responde(settings: Settings) -> None:
    unreachable_settings = settings.model_copy(update={"redis_url": "redis://localhost:1/1"})
    async with _client_for(unreachable_settings) as client:
        with structlog.testing.capture_logs() as logs:
            response = await client.post("/v1/auth/google", json={"id_token": "short"})

    assert response.status_code == 400
    warnings = [entry for entry in logs if entry.get("event") == "rate_limit_backend_unavailable"]
    assert warnings


async def test_falla_abierto_si_el_limiter_no_esta_disponible(settings: Settings) -> None:
    """Regresion (fix round 1): resolver `app.state.rate_limiter` tambien falla-abierto.

    Antes del fix, `limiter_provider()` se llamaba fuera del `try/except` de
    `_safe_hit`, asi que un provider ausente/roto tumbaba la request con 500 en
    vez de dejarla pasar.
    """
    app = create_app(settings)
    async with LifespanManager(app):
        del app.state.rate_limiter

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            health_response = await client.get("/health")
            assert health_response.status_code == 200

            with structlog.testing.capture_logs() as logs:
                auth_response = await client.post("/v1/auth/google", json={"id_token": "short"})

    assert auth_response.status_code == 400
    warnings = [entry for entry in logs if entry.get("event") == "rate_limit_backend_unavailable"]
    assert warnings
