"""Tests de integracion del router de health: liveness y readiness (spec 003 F0.4)."""

import os

import pytest
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient

from finanzia.app import create_app
from finanzia.shared.settings import Settings


@pytest.mark.integration
async def test_health_liveness(client: AsyncClient) -> None:
    response = await client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


@pytest.mark.integration
async def test_health_ready_ok_cuando_db_y_redis_responden(client: AsyncClient) -> None:
    response = await client.get("/health/ready")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "checks": {"database": "ok", "redis": "ok"},
    }


@pytest.mark.integration
async def test_health_ready_degrada_si_redis_no_es_alcanzable() -> None:
    settings_con_redis_roto = Settings(
        _env_file=None,  # pyright: ignore[reportCallIssue]
        env="test",
        database_url=os.environ.get(
            "FINANZIA_TEST_DATABASE_URL",
            "postgresql+asyncpg://finanzia:finanzia@localhost:5432/finanzia_test",
        ),
        redis_url="redis://localhost:1/1",
        jwt_secret="test-secret-test-secret-test-secret-1234",
        google_client_id="test-client",
    )
    app = create_app(settings_con_redis_roto)

    async with LifespanManager(app):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            response = await ac.get("/health/ready")

    assert response.status_code == 503
    body = response.json()
    assert body == {
        "status": "degraded",
        "checks": {"database": "ok", "redis": "error"},
    }
