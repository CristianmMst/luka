"""Fixtures compartidas por toda la suite de tests (spec 003 §4 F0.4)."""

import asyncio
import os
from collections.abc import AsyncGenerator, Awaitable, Callable
from datetime import UTC, datetime, timedelta
from pathlib import Path
from uuid import UUID, uuid4

import pytest
import redis.asyncio as redis_asyncio
from alembic import command
from alembic.config import Config
from asgi_lifespan import LifespanManager
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from support.auth import AuthedUser

from finanzia.app import create_app
from finanzia.shared.security import encode_access_token
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
        # Limites altos por defecto (Task 8/F1.4, subidos en review final item J):
        # el resto de la suite hace muchos logins/llamadas autenticadas desde la
        # misma IP de test y no debe toparse con el rate limiting real. Los limites
        # reales (bajos) se prueban aparte via `settings.model_copy(update={...})`
        # en los tests de rate limiting propios (`test_rate_limit_api.py`).
        rate_limit_auth_per_minute=100_000,
        rate_limit_user_per_minute=1_000_000,
        rate_limit_ingest_per_minute=100_000,
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


@pytest.fixture(scope="session")
async def session_factory(
    settings: Settings, migrated_db: None
) -> AsyncGenerator[async_sessionmaker[AsyncSession], None]:
    """Engine + session factory propios de los tests, independientes del de la app."""
    del migrated_db
    engine = create_async_engine(str(settings.database_url))
    factory = async_sessionmaker(engine, expire_on_commit=False)
    try:
        yield factory
    finally:
        await engine.dispose()


@pytest.fixture
async def redis_clean(settings: Settings) -> AsyncGenerator[None, None]:
    """Vacia la Redis de test (db 1) antes y despues del test (Task 8/F1.4).

    No es autouse: solo los tests de rate limiting la piden, para no interferir
    con otras claves (idempotency-key, etc.) usadas por otras suites.
    """
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        await client.flushdb()
        yield
        await client.flushdb()
    finally:
        await client.aclose()


@pytest.fixture
async def db_clean(session_factory: async_sessionmaker[AsyncSession]) -> None:
    """Vacia las tablas de usuario antes de cada test (no autouse global).

    Orden: hijos del ledger antes que sus padres, `raw_messages` (ingestion)
    antes que `users` (spec 004 SS2.1-2.10, Task 9/F1.5, F2.1). `review_queue`
    referencia `raw_messages` por PK/FK CASCADE, pero se borra explicito primero
    por claridad. `categories` nunca se trunca completa: solo se borran las
    categorias de usuario (`user_id IS NOT NULL`) para preservar el seed de las
    24 categorias del sistema.
    """
    async with session_factory() as session:
        await session.execute(text("DELETE FROM review_queue"))
        await session.execute(text("DELETE FROM merchant_rules"))
        await session.execute(text("DELETE FROM transaction_sources"))
        await session.execute(text("DELETE FROM transactions"))
        await session.execute(text("DELETE FROM linked_accounts"))
        await session.execute(text("DELETE FROM categories WHERE user_id IS NOT NULL"))
        await session.execute(text("DELETE FROM raw_messages"))
        await session.execute(text("DELETE FROM refresh_tokens"))
        await session.execute(text("DELETE FROM users"))
        await session.commit()


@pytest.fixture
def user_factory(client: AsyncClient, db_clean: None) -> Callable[..., Awaitable[AuthedUser]]:
    """Callable async que loguea un usuario fake real via `POST /v1/auth/google`."""
    del db_clean

    async def make_user(
        sub: str = "sub-1",
        email: str = "ana@example.com",
        device_info: str | None = None,
    ) -> AuthedUser:
        response = await client.post(
            "/v1/auth/google",
            json={"id_token": f"fake:{sub}:{email}", "device_info": device_info},
        )
        assert response.status_code == 200, response.text
        body = response.json()
        return AuthedUser(
            id=UUID(body["user"]["id"]),
            email=body["user"]["email"],
            access_token=body["access_token"],
            refresh_token=body["refresh_token"],
        )

    return make_user


@pytest.fixture
async def second_user(user_factory: Callable[..., Awaitable[AuthedUser]]) -> AuthedUser:
    """Segundo usuario de prueba, para casos de aislamiento entre usuarios."""
    return await user_factory(sub="sub-2", email="beatriz@example.com")


@pytest.fixture
def expired_access_token(settings: Settings) -> str:
    """Access JWT valido en forma pero vencido: emitido hace 16 minutos (TTL 15 min)."""
    return encode_access_token(
        user_id=uuid4(),
        now=datetime.now(UTC) - timedelta(minutes=16),
        ttl=timedelta(minutes=15),
        secret=settings.jwt_secret.get_secret_value(),
    )
