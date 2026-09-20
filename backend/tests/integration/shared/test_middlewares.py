"""Tests de integracion de los middlewares compartidos (spec 009 SS4-SS5)."""

import json
import re
from collections.abc import AsyncGenerator, MutableMapping
from typing import Any

import pytest
import structlog
from asgi_lifespan import LifespanManager
from fastapi import APIRouter, Request
from httpx import ASGITransport, AsyncClient

from finanzia.app import create_app
from finanzia.shared.settings import Settings

_UUID_PATTERN = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.IGNORECASE
)


@pytest.mark.integration
async def test_request_id_generado_cuando_no_se_envia(client: AsyncClient) -> None:
    response = await client.get("/health")

    assert _UUID_PATTERN.match(response.headers["x-request-id"])


@pytest.mark.integration
async def test_request_id_valido_se_repite_en_la_respuesta(client: AsyncClient) -> None:
    response = await client.get("/health", headers={"X-Request-ID": "abc-123"})

    assert response.headers["x-request-id"] == "abc-123"


@pytest.mark.integration
async def test_request_id_invalido_se_reemplaza_por_uno_generado(client: AsyncClient) -> None:
    request_id_invalido = "con espacios y mas de sesenta y cuatro caracteres 1234567890123"
    response = await client.get("/health", headers={"X-Request-ID": request_id_invalido})

    request_id_devuelto = response.headers["x-request-id"]
    assert request_id_devuelto != request_id_invalido
    assert _UUID_PATTERN.match(request_id_devuelto)


@pytest.mark.integration
async def test_cabeceras_de_seguridad_presentes_sin_hsts_en_test(client: AsyncClient) -> None:
    response = await client.get("/health")

    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["cache-control"] == "no-store"
    assert response.headers["referrer-policy"] == "no-referrer"
    assert "strict-transport-security" not in response.headers


@pytest.mark.integration
async def test_body_que_excede_el_limite_devuelve_400(
    client: AsyncClient, settings: Settings
) -> None:
    cuerpo_demasiado_grande = b"a" * (settings.max_body_bytes + 1)

    response = await client.post(
        "/health",
        content=cuerpo_demasiado_grande,
        headers={"Content-Length": str(len(cuerpo_demasiado_grande))},
    )

    assert response.status_code == 400
    body = response.json()
    assert body["error"]["code"] == "validation_error"
    assert body["error"]["field"] == "body"


@pytest.mark.integration
async def test_log_de_acceso_no_filtra_query_string(client: AsyncClient) -> None:
    with structlog.testing.capture_logs() as logs:
        response = await client.get("/health", params={"q": "secreto"})

    assert response.status_code == 200
    access_logs = [entry for entry in logs if entry.get("event") == "http_request"]
    assert access_logs, "se esperaba un log 'http_request'"
    entry = access_logs[0]
    assert "secreto" not in repr(entry)
    assert {"method", "route", "status", "duration_ms"} <= entry.keys()


@pytest.mark.integration
async def test_log_de_acceso_registra_la_plantilla_de_ruta_matcheada(
    client: AsyncClient,
) -> None:
    with structlog.testing.capture_logs() as logs:
        response = await client.get("/health")

    assert response.status_code == 200
    access_logs = [entry for entry in logs if entry.get("event") == "http_request"]
    assert access_logs
    assert access_logs[0]["route"] == "/health"


@pytest.mark.integration
async def test_log_de_acceso_marca_ruta_desconocida_como_unmatched(
    client: AsyncClient,
) -> None:
    with structlog.testing.capture_logs() as logs:
        response = await client.get("/esta-ruta-no-existe")

    assert response.status_code == 404
    access_logs = [entry for entry in logs if entry.get("event") == "http_request"]
    assert access_logs
    assert access_logs[0]["route"] == "unmatched"


@pytest.fixture
async def param_route_client(settings: Settings) -> AsyncGenerator[AsyncClient, None]:
    """App de prueba con una ruta parametrizada, para validar la plantilla en logs."""
    app = create_app(settings)
    router = APIRouter()

    @router.get("/v1/things/{thing_id}")
    async def _get_thing(thing_id: str) -> dict[str, str]:
        return {"thing_id": thing_id}

    app.include_router(router)

    async with LifespanManager(app):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac


@pytest.mark.integration
async def test_log_de_acceso_registra_plantilla_con_parametro_sin_filtrar_el_valor(
    param_route_client: AsyncClient,
) -> None:
    identificador_secreto = "id-super-secreto-12345"

    with structlog.testing.capture_logs() as logs:
        response = await param_route_client.get(f"/v1/things/{identificador_secreto}")

    assert response.status_code == 200
    access_logs = [entry for entry in logs if entry.get("event") == "http_request"]
    assert access_logs
    entry = access_logs[0]
    assert entry["route"] == "/v1/things/{thing_id}"
    assert identificador_secreto not in repr(entry)


@pytest.mark.integration
async def test_body_limit_en_streaming_sin_content_length_devuelve_400(
    settings: Settings,
) -> None:
    """Ejercita el camino de `receive` envuelto (sin `Content-Length` fiable).

    Maneja el ASGI app directamente (sin `httpx.ASGITransport`) para poder enviar
    los mensajes `http.request` con `more_body` a mano, tal como haria un cliente
    que transmite el cuerpo en streaming/chunked.
    """
    app = create_app(settings)
    router = APIRouter()

    @router.post("/_test/echo-body")
    async def _echo_body(request: Request) -> dict[str, int]:
        body = await request.body()
        return {"len": len(body)}

    app.include_router(router)

    chunk_size = (settings.max_body_bytes // 2) + 10
    pending_messages: list[dict[str, Any]] = [
        {"type": "http.request", "body": b"a" * chunk_size, "more_body": True},
        {"type": "http.request", "body": b"b" * chunk_size, "more_body": False},
    ]

    async def receive() -> dict[str, Any]:
        if pending_messages:
            return pending_messages.pop(0)
        return {"type": "http.disconnect"}

    sent_messages: list[dict[str, Any]] = []

    async def send(message: MutableMapping[str, Any]) -> None:
        sent_messages.append(dict(message))

    scope: dict[str, Any] = {
        "type": "http",
        "asgi": {"version": "3.0", "spec_version": "2.3"},
        "http_version": "1.1",
        "method": "POST",
        "scheme": "http",
        "path": "/_test/echo-body",
        "raw_path": b"/_test/echo-body",
        "query_string": b"",
        "root_path": "",
        "headers": [(b"content-type", b"application/octet-stream")],
        "client": ("testclient", 123),
        "server": ("testserver", 80),
    }

    async with LifespanManager(app):
        await app(scope, receive, send)

    start_messages = [m for m in sent_messages if m["type"] == "http.response.start"]
    assert start_messages, "se esperaba una respuesta"
    assert start_messages[0]["status"] == 400

    response_body = b"".join(
        m.get("body", b"") for m in sent_messages if m["type"] == "http.response.body"
    )
    payload = json.loads(response_body)
    assert payload["error"]["code"] == "validation_error"
    assert payload["error"]["field"] == "body"
