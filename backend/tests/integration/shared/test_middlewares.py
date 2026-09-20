"""Tests de integracion de los middlewares compartidos (spec 009 SS4-SS5)."""

import re

import pytest
import structlog
from httpx import AsyncClient

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
