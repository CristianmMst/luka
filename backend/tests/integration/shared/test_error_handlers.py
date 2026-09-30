"""Tests de integracion de los manejadores de errores (spec 005 SS1)."""

from collections.abc import AsyncGenerator

import pytest
from asgi_lifespan import LifespanManager
from fastapi import APIRouter, FastAPI, HTTPException
from httpx import ASGITransport, AsyncClient
from pydantic import BaseModel

from luka.app import create_app
from luka.shared.errors import AppError, ConflictError, NotFoundError, ValidationAppError
from luka.shared.http.error_handlers import install_error_handlers
from luka.shared.settings import Settings


class BoomError(Exception):
    """Excepcion de un modulo ficticio, sin relacion con `AppError`."""


def _boom_a_conflict(exc: Exception) -> AppError:
    del exc
    return ConflictError(message="conflicto de prueba")


class _CuerpoDePrueba(BaseModel):
    amount: int


def _build_test_app(settings: Settings) -> FastAPI:
    app = create_app(settings)
    install_error_handlers(app, module_maps=[{BoomError: _boom_a_conflict}])

    router = APIRouter()

    @router.get("/_test/not-found")
    async def _raise_not_found() -> None:
        raise NotFoundError

    @router.get("/_test/reason")
    async def _raise_with_reason() -> None:
        raise ValidationAppError(message="motivo", field="campo", reason="motivo_estable")

    @router.get("/_test/boom")
    async def _raise_boom() -> None:
        raise BoomError("da igual")

    @router.get("/_test/runtime-error")
    async def _raise_runtime_error() -> None:
        raise RuntimeError("secret detail")

    @router.post("/_test/body")
    async def _recibe_cuerpo(payload: _CuerpoDePrueba) -> dict[str, int]:
        return {"amount": payload.amount}

    @router.get("/_test/teapot")
    async def _raise_unmapped_http_exception() -> None:
        raise HTTPException(status_code=418, detail="soy una tetera, detalle interno")

    app.include_router(router)
    return app


@pytest.fixture
async def error_test_client(settings: Settings) -> AsyncGenerator[AsyncClient, None]:
    app = _build_test_app(settings)
    async with LifespanManager(app):
        # `raise_app_exceptions=False`: Starlette's ServerErrorMiddleware siempre
        # re-lanza la excepcion original despues de enviar la respuesta 500 (para que
        # el servidor ASGI real la loguee); en tests ASGITransport la propagaria al
        # cliente en vez de dejarnos inspeccionar la respuesta ya enviada.
        transport = ASGITransport(app=app, raise_app_exceptions=False)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            yield client


@pytest.mark.integration
async def test_not_found_error_no_incluye_field_cuando_es_none(
    error_test_client: AsyncClient,
) -> None:
    response = await error_test_client.get("/_test/not-found")

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "not_found"
    assert "field" not in body["error"]
    assert "reason" not in body["error"]


@pytest.mark.integration
async def test_app_error_con_reason_lo_incluye_en_el_sobre(
    error_test_client: AsyncClient,
) -> None:
    response = await error_test_client.get("/_test/reason")

    assert response.status_code == 400
    assert response.json() == {
        "error": {
            "code": "validation_error",
            "message": "motivo",
            "field": "campo",
            "reason": "motivo_estable",
        }
    }


@pytest.mark.integration
async def test_body_invalido_devuelve_validation_error_con_field(
    error_test_client: AsyncClient,
) -> None:
    response = await error_test_client.post("/_test/body", json={"amount": "x"})

    assert response.status_code == 400
    body = response.json()
    assert body["error"]["code"] == "validation_error"
    assert body["error"]["field"] == "amount"


@pytest.mark.integration
async def test_excepcion_no_controlada_no_filtra_detalle(
    error_test_client: AsyncClient,
) -> None:
    response = await error_test_client.get("/_test/runtime-error")

    assert response.status_code == 500
    body = response.json()
    assert body["error"]["code"] == "internal"
    assert "secret detail" not in response.text


@pytest.mark.integration
async def test_ruta_desconocida_devuelve_404_not_found(
    error_test_client: AsyncClient,
) -> None:
    response = await error_test_client.get("/_test/no-existe")

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


@pytest.mark.integration
async def test_module_map_convierte_excepcion_propia_en_conflict(
    error_test_client: AsyncClient,
) -> None:
    response = await error_test_client.get("/_test/boom")

    assert response.status_code == 409
    assert response.json()["error"]["code"] == "conflict"


@pytest.mark.integration
async def test_http_exception_con_status_no_mapeado_degrada_a_internal(
    error_test_client: AsyncClient,
) -> None:
    response = await error_test_client.get("/_test/teapot")

    assert response.status_code == 500
    body = response.json()
    assert body["error"]["code"] == "internal"
    assert "tetera" not in response.text
    assert "detalle interno" not in response.text
