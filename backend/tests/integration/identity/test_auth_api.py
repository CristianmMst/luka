"""Tests de integracion de `/v1/auth/*` (spec 005 SS2, spec 009 SS2.2, AC-1.4)."""

import asyncio
from collections.abc import Awaitable, Callable

import pytest
import structlog.testing
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser


@pytest.mark.integration
async def test_login_con_google_fake_devuelve_sesion_200(
    client: AsyncClient, session_factory: async_sessionmaker[AsyncSession]
) -> None:
    response = await client.post("/v1/auth/google", json={"id_token": "fake:sub-1:ana@example.com"})

    assert response.status_code == 200
    body = response.json()
    assert set(body) == {"access_token", "refresh_token", "token_type", "expires_in", "user"}
    assert body["token_type"] == "Bearer"
    assert body["expires_in"] == 900
    assert body["user"]["email"] == "ana@example.com"

    async with session_factory() as session:
        row = (
            await session.execute(text("SELECT google_sub FROM users WHERE google_sub = 'sub-1'"))
        ).first()
    assert row is not None


@pytest.mark.integration
async def test_login_no_filtra_email_ni_refresh_token_en_logs(client: AsyncClient) -> None:
    with structlog.testing.capture_logs() as captured:
        response = await client.post(
            "/v1/auth/google", json={"id_token": "fake:sub-log:log-secreto@example.com"}
        )

    assert response.status_code == 200
    refresh_token = response.json()["refresh_token"]

    for entry in captured:
        rendered = repr(entry)
        assert "log-secreto@example.com" not in rendered
        assert refresh_token not in rendered


@pytest.mark.integration
async def test_mismo_sub_otro_email_actualiza_perfil_sin_cambiar_id(
    client: AsyncClient,
) -> None:
    primero = await client.post("/v1/auth/google", json={"id_token": "fake:sub-1:ana@example.com"})
    segundo = await client.post(
        "/v1/auth/google", json={"id_token": "fake:sub-1:ana-nueva@example.com"}
    )

    assert segundo.status_code == 200
    assert segundo.json()["user"]["id"] == primero.json()["user"]["id"]
    assert segundo.json()["user"]["email"] == "ana-nueva@example.com"


@pytest.mark.integration
async def test_email_no_verificado_devuelve_401_unauthorized(client: AsyncClient) -> None:
    response = await client.post(
        "/v1/auth/google", json={"id_token": "fake:sub-2:x@y.com:unverified"}
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


@pytest.mark.integration
async def test_token_invalido_devuelve_401_unauthorized(client: AsyncClient) -> None:
    response = await client.post("/v1/auth/google", json={"id_token": "not-a-google-token-at-all"})

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


@pytest.mark.integration
async def test_id_token_faltante_devuelve_400_con_field(client: AsyncClient) -> None:
    response = await client.post("/v1/auth/google", json={})

    assert response.status_code == 400
    body = response.json()
    assert body["error"]["code"] == "validation_error"
    assert body["error"]["field"] == "id_token"


@pytest.mark.integration
async def test_campo_extra_desconocido_devuelve_400(client: AsyncClient) -> None:
    response = await client.post(
        "/v1/auth/google",
        json={"id_token": "fake:sub-1:ana@example.com", "campo_raro": "x"},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "validation_error"


@pytest.mark.integration
async def test_refresh_rota_el_token_y_el_anterior_deja_de_servir(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()

    response = await client.post("/v1/auth/refresh", json={"refresh_token": user.refresh_token})

    assert response.status_code == 200
    body = response.json()
    assert set(body) == {"access_token", "refresh_token", "token_type", "expires_in", "user"}
    assert body["refresh_token"] != user.refresh_token

    reuse = await client.post("/v1/auth/refresh", json={"refresh_token": user.refresh_token})
    assert reuse.status_code == 401
    assert reuse.json()["error"]["code"] == "unauthorized"


@pytest.mark.integration
async def test_reuso_de_refresh_rotado_revoca_toda_la_familia(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    user = await user_factory()

    rotated = await client.post("/v1/auth/refresh", json={"refresh_token": user.refresh_token})
    new_refresh = rotated.json()["refresh_token"]

    reuse_old = await client.post("/v1/auth/refresh", json={"refresh_token": user.refresh_token})
    reuse_new = await client.post("/v1/auth/refresh", json={"refresh_token": new_refresh})

    assert reuse_old.status_code == 401
    assert reuse_new.status_code == 401

    async with session_factory() as session:
        active = (
            await session.execute(
                text(
                    "SELECT count(*) FROM refresh_tokens rt "
                    "JOIN refresh_tokens rt2 ON rt.family_id = rt2.family_id "
                    "WHERE rt2.user_id = :user_id AND rt.revoked_at IS NULL"
                ),
                {"user_id": str(user.id)},
            )
        ).scalar_one()
    assert active == 0


@pytest.mark.integration
async def test_refresh_vencido_devuelve_401(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    user = await user_factory()

    async with session_factory() as session:
        await session.execute(
            text(
                "UPDATE refresh_tokens SET expires_at = now() - interval '1 day' "
                "WHERE user_id = :user_id"
            ),
            {"user_id": str(user.id)},
        )
        await session.commit()

    response = await client.post("/v1/auth/refresh", json={"refresh_token": user.refresh_token})

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


@pytest.mark.integration
async def test_dos_refresh_concurrentes_nunca_devuelven_dos_200(
    app: FastAPI, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()

    async def _refresh() -> int:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            response = await ac.post("/v1/auth/refresh", json={"refresh_token": user.refresh_token})
            return response.status_code

    status_a, status_b = await asyncio.gather(_refresh(), _refresh())

    assert (status_a, status_b).count(200) <= 1
    assert {status_a, status_b} <= {200, 401}


@pytest.mark.integration
async def test_logout_revoca_el_refresh_token(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()

    response = await client.post(
        "/v1/auth/logout",
        json={"refresh_token": user.refresh_token},
        headers=user.headers,
    )
    assert response.status_code == 204
    assert response.content == b""

    refresh_after = await client.post(
        "/v1/auth/refresh", json={"refresh_token": user.refresh_token}
    )
    assert refresh_after.status_code == 401


@pytest.mark.integration
async def test_logout_sin_bearer_devuelve_401(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()

    response = await client.post("/v1/auth/logout", json={"refresh_token": user.refresh_token})

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


@pytest.mark.integration
async def test_logout_con_refresh_token_ajeno_no_afecta_al_dueno(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    second_user: AuthedUser,
) -> None:
    owner = await user_factory()

    response = await client.post(
        "/v1/auth/logout",
        json={"refresh_token": owner.refresh_token},
        headers=second_user.headers,
    )
    assert response.status_code == 204

    still_works = await client.post("/v1/auth/refresh", json={"refresh_token": owner.refresh_token})
    assert still_works.status_code == 200
