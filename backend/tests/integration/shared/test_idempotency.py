"""Tests de integracion del middleware `Idempotency-Key` (spec 005 SS1, 009 SS4, Task 12).

Cada test construye su propia app via `create_app(settings)` con una ruta descartable
protegida por `finanzia.modules.identity.public.get_current_user_id` (los tests pueden
importar modulos; `shared` no puede). Los usuarios se crean con `user_factory`, que
loguea contra la app generica de `conftest.py`; el access token resultante es valido
contra cualquier app construida con los mismos `settings` (mismo `jwt_secret`), asi
que se reutiliza tal cual contra la app de este modulo.
"""

from collections.abc import AsyncGenerator, Awaitable, Callable
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest
import redis.asyncio as redis_asyncio
import structlog
from asgi_lifespan import LifespanManager
from fastapi import APIRouter, Depends, FastAPI, Request, status
from fastapi.responses import JSONResponse, PlainTextResponse
from httpx import ASGITransport, AsyncClient
from support.auth import AuthedUser

from finanzia.app import create_app
from finanzia.modules.identity.public import get_current_user_id
from finanzia.shared.security import encode_access_token
from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration


@pytest.fixture(autouse=True)
async def _redis_limpio(redis_clean: None) -> None:
    """Evita que las claves `idem:*` se filtren entre tests de este modulo."""
    del redis_clean


@pytest.fixture(autouse=True)
async def _tablas_limpias(db_clean: None) -> None:
    del db_clean


def _build_app(settings: Settings) -> tuple[FastAPI, dict[str, int]]:
    """App con dos rutas descartables bajo `/v1/`: una que cuenta llamadas por usuario
    y otra que siempre responde 500 (para probar que las respuestas 5xx no se guardan).
    """
    app = create_app(settings)
    counters: dict[str, int] = {}
    router = APIRouter()

    @router.post("/v1/idem-test", status_code=status.HTTP_201_CREATED)
    async def _idem_test(
        request: Request, user_id: UUID = Depends(get_current_user_id)
    ) -> dict[str, object]:
        body = await request.json()
        key = str(user_id)
        counters[key] = counters.get(key, 0) + 1
        return {"n": counters[key], "echo": body}

    @router.get("/v1/idem-test", status_code=status.HTTP_200_OK)
    async def _idem_test_get(user_id: UUID = Depends(get_current_user_id)) -> dict[str, str]:
        del user_id
        return {"ok": "true"}

    @router.post("/v1/idem-fail")
    async def _idem_fail(user_id: UUID = Depends(get_current_user_id)) -> JSONResponse:
        key = f"fail:{user_id}"
        counters[key] = counters.get(key, 0) + 1
        return JSONResponse(
            status_code=500, content={"error": {"code": "internal", "message": "boom"}}
        )

    @router.post("/v1/idem-big", status_code=status.HTTP_201_CREATED)
    async def _idem_big(user_id: UUID = Depends(get_current_user_id)) -> PlainTextResponse:
        key = f"big:{user_id}"
        counters[key] = counters.get(key, 0) + 1
        return PlainTextResponse("a" * (300 * 1024), status_code=status.HTTP_201_CREATED)

    app.include_router(router)
    return app, counters


@asynccontextmanager
async def _client_for(app: FastAPI) -> AsyncGenerator[AsyncClient, None]:
    async with LifespanManager(app):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac


async def _redis_ttl(settings: Settings, key: str) -> int:
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        return await client.ttl(key)
    finally:
        await client.aclose()


async def _redis_exists(settings: Settings, key: str) -> int:
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        return await client.exists(key)
    finally:
        await client.aclose()


async def test_mismo_key_y_body_replay_la_segunda_respuesta(
    settings: Settings, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    app, counters = _build_app(settings)
    idem_key = str(uuid4())
    headers = {**user.headers, "Idempotency-Key": idem_key}

    async with _client_for(app) as client:
        first = await client.post("/v1/idem-test", json={"amount": 100}, headers=headers)
        second = await client.post("/v1/idem-test", json={"amount": 100}, headers=headers)

    assert first.status_code == 201
    assert second.status_code == 201
    assert first.json() == second.json()
    assert "idempotency-replayed" not in first.headers
    assert second.headers["idempotency-replayed"] == "true"
    assert counters[str(user.id)] == 1


async def test_mismo_key_con_body_distinto_devuelve_409(
    settings: Settings, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    app, counters = _build_app(settings)
    idem_key = str(uuid4())

    async with _client_for(app) as client:
        first = await client.post(
            "/v1/idem-test",
            json={"amount": 100},
            headers={**user.headers, "Idempotency-Key": idem_key},
        )
        second = await client.post(
            "/v1/idem-test",
            json={"amount": 200},
            headers={**user.headers, "Idempotency-Key": idem_key},
        )

    assert first.status_code == 201
    assert second.status_code == 409
    error = second.json()["error"]
    assert error["code"] == "conflict"
    assert error["field"] == "Idempotency-Key"
    assert counters[str(user.id)] == 1


async def test_idempotency_key_no_uuid_devuelve_400(
    settings: Settings, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    app, counters = _build_app(settings)

    async with _client_for(app) as client:
        response = await client.post(
            "/v1/idem-test",
            json={"amount": 1},
            headers={**user.headers, "Idempotency-Key": "no-es-un-uuid"},
        )

    assert response.status_code == 400
    error = response.json()["error"]
    assert error["code"] == "validation_error"
    assert error["field"] == "Idempotency-Key"
    assert str(user.id) not in counters


async def test_sin_header_ejecuta_dos_veces(
    settings: Settings, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    app, counters = _build_app(settings)

    async with _client_for(app) as client:
        first = await client.post("/v1/idem-test", json={"amount": 1}, headers=user.headers)
        second = await client.post("/v1/idem-test", json={"amount": 1}, headers=user.headers)

    assert first.status_code == 201
    assert second.status_code == 201
    assert first.json()["n"] == 1
    assert second.json()["n"] == 2
    assert counters[str(user.id)] == 2


async def test_dos_usuarios_con_el_mismo_key_son_independientes(
    settings: Settings, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user_a = await user_factory(sub="sub-idem-a", email="idem-a@example.com")
    user_b = await user_factory(sub="sub-idem-b", email="idem-b@example.com")
    app, counters = _build_app(settings)
    idem_key = str(uuid4())

    async with _client_for(app) as client:
        response_a = await client.post(
            "/v1/idem-test",
            json={"amount": 1},
            headers={**user_a.headers, "Idempotency-Key": idem_key},
        )
        response_b = await client.post(
            "/v1/idem-test",
            json={"amount": 1},
            headers={**user_b.headers, "Idempotency-Key": idem_key},
        )

    assert response_a.status_code == 201
    assert response_b.status_code == 201
    assert counters[str(user_a.id)] == 1
    assert counters[str(user_b.id)] == 1


async def test_ttl_almacenado_es_aproximadamente_24h(
    settings: Settings, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    app, _counters = _build_app(settings)
    idem_key = str(uuid4())

    async with _client_for(app) as client:
        response = await client.post(
            "/v1/idem-test",
            json={"amount": 1},
            headers={**user.headers, "Idempotency-Key": idem_key},
        )
    assert response.status_code == 201

    ttl = await _redis_ttl(settings, f"idem:{user.id}:{idem_key}")
    assert 86000 <= ttl <= 86400


async def test_respuesta_500_no_se_almacena(
    settings: Settings, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    app, counters = _build_app(settings)
    idem_key = str(uuid4())
    headers = {**user.headers, "Idempotency-Key": idem_key}

    async with _client_for(app) as client:
        first = await client.post("/v1/idem-fail", json={"amount": 1}, headers=headers)
        second = await client.post("/v1/idem-fail", json={"amount": 1}, headers=headers)

    assert first.status_code == 500
    assert second.status_code == 500
    assert counters[f"fail:{user.id}"] == 2


async def test_el_lock_se_libera_despues_de_la_request(
    settings: Settings, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    app, _counters = _build_app(settings)
    idem_key = str(uuid4())

    async with _client_for(app) as client:
        response = await client.post(
            "/v1/idem-test",
            json={"amount": 1},
            headers={**user.headers, "Idempotency-Key": idem_key},
        )
    assert response.status_code == 201

    exists = await _redis_exists(settings, f"idem:{user.id}:{idem_key}:lock")
    assert exists == 0


async def test_get_nunca_se_toca(
    settings: Settings, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    user = await user_factory()
    app, _counters = _build_app(settings)
    idem_key = str(uuid4())

    async with _client_for(app) as client:
        first = await client.get(
            "/v1/idem-test", headers={**user.headers, "Idempotency-Key": idem_key}
        )
        second = await client.get(
            "/v1/idem-test", headers={**user.headers, "Idempotency-Key": idem_key}
        )

    assert first.status_code == 200
    assert second.status_code == 200
    assert "idempotency-replayed" not in first.headers
    assert "idempotency-replayed" not in second.headers


async def test_lock_ocupado_devuelve_409(
    settings: Settings, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    """Regresion (fix round 1): rama (b) del middleware, lock ya tomado por otra request."""
    user = await user_factory()
    app, counters = _build_app(settings)
    idem_key = str(uuid4())
    lock_key = f"idem:{user.id}:{idem_key}:lock"

    async with _client_for(app) as client:
        acquired = await app.state.redis.set(lock_key, b"1", nx=True, ex=30)
        assert acquired
        response = await client.post(
            "/v1/idem-test",
            json={"amount": 1},
            headers={**user.headers, "Idempotency-Key": idem_key},
        )

    assert response.status_code == 409
    error = response.json()["error"]
    assert error["code"] == "conflict"
    assert "field" not in error
    assert str(user.id) not in counters


async def test_respuesta_demasiado_grande_no_se_almacena_y_reejecuta(
    settings: Settings, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    """Regresion (fix round 1): respuestas > 256 KiB no se guardan (re-ejecutan)."""
    user = await user_factory()
    app, counters = _build_app(settings)
    idem_key = str(uuid4())
    headers = {**user.headers, "Idempotency-Key": idem_key}

    async with _client_for(app) as client:
        with structlog.testing.capture_logs() as logs:
            first = await client.post("/v1/idem-big", json={}, headers=headers)
            second = await client.post("/v1/idem-big", json={}, headers=headers)

    assert first.status_code == 201
    assert second.status_code == 201
    assert counters[f"big:{user.id}"] == 2
    warnings = [entry for entry in logs if entry.get("event") == "idempotency_response_too_large"]
    assert warnings
    assert all(entry["size"] > 256 * 1024 for entry in warnings)


async def test_falla_abierto_si_redis_no_responde(settings: Settings) -> None:
    unreachable_settings = settings.model_copy(update={"redis_url": "redis://localhost:1/1"})
    app, counters = _build_app(unreachable_settings)
    token = encode_access_token(
        user_id=uuid4(),
        now=datetime.now(UTC),
        ttl=timedelta(minutes=15),
        secret=settings.jwt_secret.get_secret_value(),
    )
    headers = {"Authorization": f"Bearer {token}", "Idempotency-Key": str(uuid4())}

    async with _client_for(app) as client:
        with structlog.testing.capture_logs() as logs:
            response = await client.post("/v1/idem-test", json={"amount": 1}, headers=headers)

    assert response.status_code == 201
    assert sum(counters.values()) == 1
    warnings = [entry for entry in logs if entry.get("event") == "idempotency_backend_unavailable"]
    assert warnings
