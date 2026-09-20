"""Tests de integracion de `GET /v1/me` (spec 005 SS2)."""

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser

from finanzia.shared.security import encode_access_token


@pytest.mark.integration
async def test_sin_token_devuelve_401_unauthorized(client: AsyncClient) -> None:
    response = await client.get("/v1/me")

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


@pytest.mark.integration
async def test_access_token_vencido_devuelve_401_token_expired(
    client: AsyncClient, expired_access_token: str
) -> None:
    response = await client.get(
        "/v1/me", headers={"Authorization": f"Bearer {expired_access_token}"}
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "token_expired"


@pytest.mark.integration
async def test_token_firmado_con_otro_secreto_devuelve_401_unauthorized(
    client: AsyncClient,
) -> None:
    token = encode_access_token(
        user_id=uuid4(),
        now=datetime.now(UTC),
        ttl=timedelta(minutes=15),
        secret="otro-secreto-completamente-distinto-99999",
    )

    response = await client.get("/v1/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


@pytest.mark.integration
async def test_authorization_basic_devuelve_401(client: AsyncClient) -> None:
    response = await client.get("/v1/me", headers={"Authorization": "Basic abc"})

    assert response.status_code == 401


@pytest.mark.integration
async def test_token_valido_devuelve_perfil_200(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()

    response = await client.get("/v1/me", headers=user.headers)

    assert response.status_code == 200
    body = response.json()
    assert body["email"] == "ana@example.com"
    assert body["connections"] == {"gmail": "none", "notifications": "none"}
    assert body["consents"] == {}


@pytest.mark.integration
async def test_usuario_borrado_tras_login_devuelve_401(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    user = await user_factory()

    async with session_factory() as session:
        await session.execute(text("DELETE FROM users WHERE id = :id"), {"id": str(user.id)})
        await session.commit()

    response = await client.get("/v1/me", headers=user.headers)

    assert response.status_code == 401
