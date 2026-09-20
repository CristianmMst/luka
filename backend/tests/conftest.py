"""Fixtures compartidas por toda la suite de tests (spec 003 §4 F0.4)."""

import asyncio
import os
from collections.abc import AsyncGenerator
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from asgi_lifespan import LifespanManager
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

from finanzia.app import create_app
from finanzia.shared.settings import Settings

_BACKEND_DIR = Path(__file__).resolve().parent.parent
_ALEMBIC_INI = _BACKEND_DIR / "alembic.ini"


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


@pytest.fixture(scope="session")
async def migrated_db(settings: Settings) -> None:
    """Aplica `alembic upgrade head` contra `settings.database_url` (finanzia_test).

    No es autouse: los tests que necesitan tablas (a partir de Task 7) la piden
    explicitamente. `client`/`app` no dependen de esta fixture porque los tests de
    health no requieren tablas.

    Alembic expone una API sincrona pero `migrations/env.py` corre con
    `asyncio.run(...)`; se ejecuta en un hilo aparte via `asyncio.to_thread` para no
    chocar con el loop de sesion de pytest-asyncio (`asyncio.run` no admite loops
    anidados).
    """
    cfg = Config(str(_ALEMBIC_INI))
    cfg.set_main_option("script_location", str(_BACKEND_DIR / "migrations"))
    cfg.set_main_option("sqlalchemy.url", str(settings.database_url))
    await asyncio.to_thread(command.upgrade, cfg, "head")
