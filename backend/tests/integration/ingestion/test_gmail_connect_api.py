"""Tests de integracion de `/v1/gmail/connect` y `/v1/gmail/status` (F3.3, spec 005 §3).

La app usa el `GoogleGmailClient` real sobre `httpx.MockTransport` (`FakeGoogle`):
se ejercitan router, casos de uso, cifrado, repositorio SQL y adapter httpx.
"""

from collections.abc import AsyncGenerator, Awaitable, Callable

import httpx
import pytest
import structlog.testing
from fastapi import FastAPI
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.fake_google import (
    ACCESS_TOKEN,
    ACCOUNT_EMAIL,
    HISTORY_ID,
    REFRESH_TOKEN,
    FakeGoogle,
)
from support.gmail_connections import insert_gmail_connection
from support.google_stub import create_test_app

from finanzia.modules.ingestion.infrastructure.gmail_client import build_gmail_client
from finanzia.modules.ingestion.infrastructure.repositories import (
    SqlAlchemyGmailConnectionRepository,
)
from finanzia.modules.ingestion.infrastructure.token_cipher import AesGcmTokenCipher
from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration

_CODE = "4/0server-auth-code-secreto"
_WATCH_EXPIRES = "2026-05-08T12:00:00Z"


@pytest.fixture
def google() -> FakeGoogle:
    return FakeGoogle()


@pytest.fixture
async def app(settings: Settings, google: FakeGoogle) -> AsyncGenerator[FastAPI, None]:
    """Sobrescribe el `app` global: mismo `create_test_app`, Gmail sobre MockTransport."""
    async with httpx.AsyncClient(transport=google.transport()) as http:
        yield create_test_app(settings, gmail_client=build_gmail_client(settings, http))


async def _stored_refresh_token(
    session_factory: async_sessionmaker[AsyncSession], settings: Settings, user: AuthedUser
) -> str | None:
    async with session_factory() as session:
        found = await SqlAlchemyGmailConnectionRepository(session).get(user.id)
    if found is None:
        return None
    return AesGcmTokenCipher.from_settings(settings).decrypt(user.id, found.refresh_token_enc)


# --- Authz ----------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("method", "path"),
    [("POST", "/v1/gmail/connect"), ("DELETE", "/v1/gmail/connect"), ("GET", "/v1/gmail/status")],
)
async def test_sin_token_responde_401(client: AsyncClient, method: str, path: str) -> None:
    response = await client.request(method, path, json={"server_auth_code": _CODE})
    assert response.status_code == 401


async def test_cada_usuario_solo_ve_y_borra_su_conexion(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
) -> None:
    ana = await user_factory()
    beatriz = await user_factory(sub="sub-2", email="beatriz@example.com")
    connect = await client.post(
        "/v1/gmail/connect", json={"server_auth_code": _CODE}, headers=ana.headers
    )
    assert connect.status_code == 200

    other_status = await client.get("/v1/gmail/status", headers=beatriz.headers)
    other_delete = await client.delete("/v1/gmail/connect", headers=beatriz.headers)

    assert other_status.json()["status"] == "disconnected"
    assert other_delete.status_code == 204
    # El DELETE de Beatriz no toco la conexion de Ana.
    assert await _stored_refresh_token(session_factory, settings, ana) == REFRESH_TOKEN
    own = await client.get("/v1/gmail/status", headers=ana.headers)
    assert own.json()["status"] == "active"


# --- POST /v1/gmail/connect -----------------------------------------------------------


async def test_connect_guarda_cifrado_crea_watch_y_responde_el_estado(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    google: FakeGoogle,
) -> None:
    user = await user_factory()

    with structlog.testing.capture_logs() as captured:
        response = await client.post(
            "/v1/gmail/connect", json={"server_auth_code": _CODE}, headers=user.headers
        )

    assert response.status_code == 200, response.text
    assert response.json() == {
        "status": "active",
        "email": ACCOUNT_EMAIL,
        "watch_expires_at": _WATCH_EXPIRES,
    }
    assert google.operations() == ["exchange", "profile", "refresh", "watch"]
    assert google.requests[0][1]["code"] == _CODE
    assert google.requests[3][1]["topicName"] == settings.gmail_pubsub_topic

    async with session_factory() as session:
        stored = await SqlAlchemyGmailConnectionRepository(session).get(user.id)
    assert stored is not None
    assert stored.history_id == HISTORY_ID
    assert REFRESH_TOKEN.encode() not in stored.refresh_token_enc
    assert await _stored_refresh_token(session_factory, settings, user) == REFRESH_TOKEN

    for entry in captured:
        rendered = repr(entry)
        for secret in (_CODE, REFRESH_TOKEN, ACCESS_TOKEN, ACCOUNT_EMAIL):
            assert secret not in rendered
    assert any(entry["event"] == "gmail_connected" for entry in captured)


async def test_connect_con_codigo_invalido_responde_400_sin_guardar(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    google: FakeGoogle,
) -> None:
    user = await user_factory()
    google.status_by_operation["exchange"] = 400  # invalid_grant

    response = await client.post(
        "/v1/gmail/connect", json={"server_auth_code": _CODE}, headers=user.headers
    )

    assert response.status_code == 400
    error = response.json()["error"]
    assert error["code"] == "validation_error"
    assert error["field"] == "server_auth_code"
    assert _CODE not in response.text
    assert await _stored_refresh_token(session_factory, settings, user) is None


async def test_connect_sin_refresh_token_responde_400_pidiendo_consentimiento(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    google: FakeGoogle,
) -> None:
    user = await user_factory()
    google.refresh_token = None

    response = await client.post(
        "/v1/gmail/connect", json={"server_auth_code": _CODE}, headers=user.headers
    )

    assert response.status_code == 400
    error = response.json()["error"]
    assert error["code"] == "validation_error"
    assert error["field"] == "server_auth_code"
    assert "consentimiento" in error["message"]


async def test_connect_con_google_caido_en_el_canje_responde_503(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    google: FakeGoogle,
) -> None:
    user = await user_factory()
    google.status_by_operation["exchange"] = 503

    response = await client.post(
        "/v1/gmail/connect", json={"server_auth_code": _CODE}, headers=user.headers
    )

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "upstream_unavailable"


async def test_connect_con_watch_fallido_guarda_la_conexion_en_error(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    google: FakeGoogle,
) -> None:
    user = await user_factory()
    google.status_by_operation["watch"] = 503

    response = await client.post(
        "/v1/gmail/connect", json={"server_auth_code": _CODE}, headers=user.headers
    )

    assert response.status_code == 200
    assert response.json() == {
        "status": "error",
        "email": ACCOUNT_EMAIL,
        "watch_expires_at": None,
    }
    assert await _stored_refresh_token(session_factory, settings, user) == REFRESH_TOKEN


@pytest.mark.parametrize(
    ("body", "field"),
    [({}, "server_auth_code"), ({"server_auth_code": ""}, "server_auth_code")],
)
async def test_connect_con_body_invalido_responde_400(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    google: FakeGoogle,
    body: dict[str, str],
    field: str,
) -> None:
    user = await user_factory()

    response = await client.post("/v1/gmail/connect", json=body, headers=user.headers)

    assert response.status_code == 400
    assert response.json()["error"]["field"] == field
    assert google.requests == []


# --- DELETE /v1/gmail/connect ---------------------------------------------------------


async def test_disconnect_detiene_revoca_y_borra(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    google: FakeGoogle,
) -> None:
    user = await user_factory()
    await client.post("/v1/gmail/connect", json={"server_auth_code": _CODE}, headers=user.headers)
    google.requests.clear()

    response = await client.delete("/v1/gmail/connect", headers=user.headers)

    assert response.status_code == 204
    assert response.content == b""
    assert google.operations() == ["refresh", "stop", "revoke"]
    assert google.requests[2][1]["token"] == REFRESH_TOKEN
    assert await _stored_refresh_token(session_factory, settings, user) is None
    status = await client.get("/v1/gmail/status", headers=user.headers)
    assert status.json()["status"] == "disconnected"


async def test_disconnect_con_google_caido_borra_igual(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    google: FakeGoogle,
) -> None:
    user = await user_factory()
    await client.post("/v1/gmail/connect", json={"server_auth_code": _CODE}, headers=user.headers)
    google.status_by_operation.update({"refresh": 503, "revoke": 503})

    response = await client.delete("/v1/gmail/connect", headers=user.headers)

    assert response.status_code == 204
    assert await _stored_refresh_token(session_factory, settings, user) is None


async def test_disconnect_con_token_indescifrable_borra_sin_llamar_a_google(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    google: FakeGoogle,
) -> None:
    user = await user_factory()
    await insert_gmail_connection(session_factory, user_id=user.id, refresh_token_enc=b"basura")

    response = await client.delete("/v1/gmail/connect", headers=user.headers)

    assert response.status_code == 204
    assert google.requests == []
    status = await client.get("/v1/gmail/status", headers=user.headers)
    assert status.json()["status"] == "disconnected"


async def test_disconnect_sin_conexion_responde_204(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    google: FakeGoogle,
) -> None:
    user = await user_factory()

    response = await client.delete("/v1/gmail/connect", headers=user.headers)

    assert response.status_code == 204
    assert google.requests == []


# --- GET /v1/gmail/status -------------------------------------------------------------


async def test_status_sin_conexion_es_disconnected(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()

    response = await client.get("/v1/gmail/status", headers=user.headers)

    assert response.status_code == 200
    assert response.json() == {
        "status": "disconnected",
        "email": None,
        "last_sync_at": None,
        "watch_expires_at": None,
    }


async def test_status_con_conexion_no_expone_el_token(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    await client.post("/v1/gmail/connect", json={"server_auth_code": _CODE}, headers=user.headers)

    response = await client.get("/v1/gmail/status", headers=user.headers)

    assert response.status_code == 200
    assert response.json() == {
        "status": "active",
        "email": ACCOUNT_EMAIL,
        "last_sync_at": None,
        "watch_expires_at": _WATCH_EXPIRES,
    }
    assert REFRESH_TOKEN not in response.text
