"""Fixtures compartidas por toda la suite de tests (spec 003 §4 F0.4)."""

import os
from collections.abc import AsyncGenerator

import pytest
from asgi_lifespan import LifespanManager
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

from finanzia.app import create_app
from finanzia.shared.settings import Settings


@pytest.fixture(scope="session")
def settings() -> Settings:
    """Settings de test: apunta a `finanzia_test` y a la db 1 de Redis."""
    return Settings(
        _env_file=None,  # pyright: ignore[reportCallIssue]
        env="test",
        database_url=os.environ.get(
            "FINANZIA_TEST_DATABASE_URL",
            "postgresql+asyncpg://finanzia:finanzia@localhost:5432/finanzia_test",
        ),
        redis_url=os.environ.get("FINANZIA_TEST_REDIS_URL", "redis://localhost:6379/1"),
        jwt_secret="test-secret-test-secret-test-secret-1234",
        google_client_id="test-client",
        google_verifier="fake",
    )


@pytest.fixture
def app(settings: Settings) -> FastAPI:
    """Instancia de la app FastAPI construida con los settings de test."""
    return create_app(settings)


@pytest.fixture
async def client(app: FastAPI) -> AsyncGenerator[AsyncClient, None]:
    """Cliente HTTP asincrono contra la app, con el lifespan ya ejecutado."""
    async with LifespanManager(app):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac
