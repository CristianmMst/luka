"""Tests de integracion de `POST /v1/webhooks/gmail` (F3.4, spec 005 §4).

El verificador OIDC es el real (`GoogleOidcPushVerifier`) con certificados de
prueba (`support.oidc`); la cola es la de arq sobre la Redis de test, asi que se
comprueba el job realmente encolado.
"""

from __future__ import annotations

import base64
import json
from collections.abc import AsyncGenerator, Awaitable, Callable
from datetime import timedelta
from typing import Any

import pytest
import redis.asyncio as redis_asyncio
import redis.exceptions
import structlog.testing
from arq.connections import ArqRedis
from arq.jobs import JobDef
from fastapi import FastAPI
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.gmail_connections import insert_gmail_connection
from support.oidc import PushClaims, sign_push_token

from luka.modules.ingestion.infrastructure.gmail_sync import ArqGmailSyncQueue
from luka.shared.settings import Settings

pytestmark = pytest.mark.integration

_URL = "/v1/webhooks/gmail"
_ACCOUNT = "cuenta-push-secreta@gmail.com"


def _envelope(data: dict[str, Any]) -> dict[str, Any]:
    encoded = base64.b64encode(json.dumps(data).encode()).decode()
    return {
        "message": {
            "data": encoded,
            "messageId": "136969346945",
            "publishTime": "2026-05-01T12:00:00Z",
        },
        "subscription": "projects/test-project/subscriptions/gmail-push",
    }


def _push(email: str = _ACCOUNT, history_id: int = 9001) -> dict[str, Any]:
    return _envelope({"emailAddress": email, "historyId": history_id})


def _auth(token: str | None = None) -> dict[str, str]:
    return {"Authorization": f"Bearer {token or sign_push_token()}"}


@pytest.fixture
async def arq_redis(settings: Settings, redis_clean: None) -> AsyncGenerator[ArqRedis, None]:
    del redis_clean
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        yield ArqRedis(connection_pool=client.connection_pool)
    finally:
        await client.aclose()


async def _queued(arq_redis: ArqRedis) -> list[tuple[str, tuple[Any, ...]]]:
    jobs: list[JobDef] = await arq_redis.queued_jobs()
    return sorted((job.function, job.args) for job in jobs)


async def test_push_valido_encola_sync_gmail_y_responde_204(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    arq_redis: ArqRedis,
) -> None:
    user = await user_factory()
    await insert_gmail_connection(session_factory, user_id=user.id, email=_ACCOUNT)

    with structlog.testing.capture_logs() as captured:
        response = await client.post(_URL, json=_push(history_id=9001), headers=_auth())

    assert response.status_code == 204, response.text
    assert response.content == b""
    assert await _queued(arq_redis) == [("sync_gmail", (str(user.id), 9001))]
    assert any(entry["event"] == "gmail_push_received" for entry in captured)
    for entry in captured:
        assert _ACCOUNT not in repr(entry)


async def test_push_encola_un_job_por_usuario_conectado_a_la_cuenta(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    second_user: AuthedUser,
    session_factory: async_sessionmaker[AsyncSession],
    arq_redis: ArqRedis,
) -> None:
    ana = await user_factory()
    await insert_gmail_connection(session_factory, user_id=ana.id, email=_ACCOUNT)
    await insert_gmail_connection(session_factory, user_id=second_user.id, email=_ACCOUNT)

    response = await client.post(_URL, json=_push(), headers=_auth())

    assert response.status_code == 204
    assert await _queued(arq_redis) == sorted(
        [("sync_gmail", (str(ana.id), 9001)), ("sync_gmail", (str(second_user.id), 9001))]
    )


@pytest.mark.parametrize(
    "headers",
    [
        {},
        {"Authorization": "Basic abc"},
        {"Authorization": "Bearer "},
        {"Authorization": "Bearer no-es-un-jwt"},
        _auth(sign_push_token(PushClaims(aud="https://otra-audiencia.example.com"))),
        _auth(sign_push_token(PushClaims(email="intruso@otro.iam.gserviceaccount.com"))),
        _auth(sign_push_token(PushClaims(email_verified=False))),
    ],
    ids=[
        "sin_header",
        "basic",
        "bearer_vacio",
        "ilegible",
        "otra_audiencia",
        "otro_email",
        "sin_verificar",
    ],
)
async def test_token_invalido_responde_403_sin_encolar(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    arq_redis: ArqRedis,
    headers: dict[str, str],
) -> None:
    user = await user_factory()
    await insert_gmail_connection(session_factory, user_id=user.id, email=_ACCOUNT)

    response = await client.post(_URL, json=_push(), headers=headers)

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "forbidden"
    assert await _queued(arq_redis) == []


async def test_token_expirado_responde_403(client: AsyncClient, arq_redis: ArqRedis) -> None:
    token = sign_push_token(PushClaims(expires_in=timedelta(minutes=-5)))

    response = await client.post(_URL, json=_push(), headers=_auth(token))

    assert response.status_code == 403
    assert await _queued(arq_redis) == []


async def test_el_bearer_de_la_app_no_sirve_en_el_webhook(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]], arq_redis: ArqRedis
) -> None:
    user = await user_factory()

    response = await client.post(_URL, json=_push(), headers=user.headers)

    assert response.status_code == 403


async def test_token_invalido_con_cuerpo_ilegible_responde_403_no_400(
    client: AsyncClient, arq_redis: ArqRedis
) -> None:
    # El token se verifica antes de mirar el cuerpo: un anonimo nunca ve un 400.
    response = await client.post(_URL, content=b"basura", headers={"content-type": "text/plain"})

    assert response.status_code == 403


@pytest.mark.parametrize(
    "body",
    [
        b"no es json",
        json.dumps({"message": {}}).encode(),
        json.dumps(_envelope({"historyId": 1})).encode(),
        json.dumps({"message": {"data": "@@@"}}).encode(),
    ],
    ids=["no_json", "sin_data", "sin_email", "data_no_base64"],
)
async def test_envelope_malformado_responde_204_sin_encolar(
    client: AsyncClient, arq_redis: ArqRedis, body: bytes
) -> None:
    with structlog.testing.capture_logs() as captured:
        response = await client.post(
            _URL, content=body, headers={**_auth(), "content-type": "application/json"}
        )

    assert response.status_code == 204
    assert await _queued(arq_redis) == []
    assert any(entry["event"] == "gmail_push_ignored" for entry in captured)


@pytest.mark.parametrize("stored_status", [None, "revoked", "error"])
async def test_cuenta_desconocida_o_inactiva_responde_204_sin_encolar(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    arq_redis: ArqRedis,
    stored_status: str | None,
) -> None:
    user = await user_factory()
    if stored_status is not None:
        await insert_gmail_connection(
            session_factory, user_id=user.id, email=_ACCOUNT, status=stored_status
        )

    response = await client.post(_URL, json=_push(), headers=_auth())

    assert response.status_code == 204
    assert await _queued(arq_redis) == []


async def test_webhook_no_aplica_idempotency_key(client: AsyncClient, arq_redis: ArqRedis) -> None:
    # Una `Idempotency-Key` invalida daria 400 en cualquier POST de la app.
    response = await client.post(
        _URL, json=_push(), headers={**_auth(), "Idempotency-Key": "no-es-uuid"}
    )

    assert response.status_code == 204


class _DownArq:
    """`ArqRedis` cuya conexion falla, como una Redis caida."""

    async def enqueue_job(self, *args: object, **kwargs: object) -> None:
        del args, kwargs
        raise redis.exceptions.ConnectionError("redis caido")


async def test_fallo_al_encolar_responde_503_para_que_pubsub_reintente(
    app: FastAPI,
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    user = await user_factory()
    await insert_gmail_connection(session_factory, user_id=user.id, email=_ACCOUNT)
    app.state.gmail_sync_queue = ArqGmailSyncQueue(_DownArq())  # type: ignore[arg-type]

    response = await client.post(_URL, json=_push(), headers=_auth())

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "upstream_unavailable"
