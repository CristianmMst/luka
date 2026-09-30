"""Tests unitarios de paginacion por cursor opaco (spec 005 SS1, Task 12)."""

import base64
import json
from datetime import UTC, datetime, timedelta, timezone
from uuid import uuid4

import pytest
from fastapi import Depends, FastAPI
from httpx import ASGITransport, AsyncClient

from luka.shared.errors import ValidationAppError
from luka.shared.http.error_handlers import install_error_handlers
from luka.shared.http.pagination import PageParams, decode_cursor, encode_cursor, page_params


def _b64(payload: object) -> str:
    raw = json.dumps(payload).encode("utf-8")
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


@pytest.mark.unit
@pytest.mark.parametrize("kind", ["occurred", "updated"])
def test_roundtrip_preserva_sort_key_e_id(kind: str) -> None:
    sort_key = datetime(2026, 8, 5, 14, 30, tzinfo=UTC)
    cursor_id = uuid4()

    raw = encode_cursor(sort_key, cursor_id, kind)  # type: ignore[arg-type]
    decoded_sort_key, decoded_id = decode_cursor(raw, kind)  # type: ignore[arg-type]

    assert decoded_sort_key == sort_key
    assert decoded_id == cursor_id


@pytest.mark.unit
def test_roundtrip_preserva_el_instante_con_offset_distinto_de_utc() -> None:
    bogota = timezone(timedelta(hours=-5))
    sort_key = datetime(2026, 8, 5, 9, 30, tzinfo=bogota)
    cursor_id = uuid4()

    raw = encode_cursor(sort_key, cursor_id, "occurred")
    decoded_sort_key, decoded_id = decode_cursor(raw, "occurred")

    assert decoded_sort_key == sort_key
    assert decoded_id == cursor_id


@pytest.mark.unit
def test_cursor_codificado_no_lleva_padding_base64() -> None:
    raw = encode_cursor(datetime.now(UTC), uuid4(), "occurred")
    assert "=" not in raw


@pytest.mark.unit
def test_decodificar_con_kind_distinto_lanza_validation_error_con_field_cursor() -> None:
    raw = encode_cursor(datetime.now(UTC), uuid4(), "occurred")

    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "updated")

    assert exc_info.value.field == "cursor"


@pytest.mark.unit
@pytest.mark.parametrize(
    "raw",
    [
        "",
        "###no-es-base64###",
        "not-base64!!!",
    ],
)
def test_base64_invalido_lanza_validation_error(raw: str) -> None:
    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "occurred")
    assert exc_info.value.field == "cursor"


@pytest.mark.unit
def test_base64_valido_pero_json_invalido_lanza_validation_error() -> None:
    raw = base64.urlsafe_b64encode(b"esto no es json").rstrip(b"=").decode("ascii")

    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "occurred")
    assert exc_info.value.field == "cursor"


@pytest.mark.unit
def test_json_sin_claves_requeridas_lanza_validation_error() -> None:
    raw = _b64({"solo": "esto"})

    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "occurred")
    assert exc_info.value.field == "cursor"


@pytest.mark.unit
def test_uuid_invalido_lanza_validation_error() -> None:
    raw = _b64({"k": "occurred", "t": datetime.now(UTC).isoformat(), "i": "no-es-un-uuid"})

    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "occurred")
    assert exc_info.value.field == "cursor"


@pytest.mark.unit
def test_datetime_naive_lanza_validation_error() -> None:
    raw = _b64({"k": "occurred", "t": "2026-08-05T14:30:00", "i": str(uuid4())})

    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "occurred")
    assert exc_info.value.field == "cursor"


@pytest.mark.unit
def test_datetime_invalida_lanza_validation_error() -> None:
    raw = _b64({"k": "occurred", "t": "no-es-una-fecha", "i": str(uuid4())})

    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "occurred")
    assert exc_info.value.field == "cursor"


@pytest.mark.unit
def test_id_no_string_lanza_validation_error() -> None:
    """Regresion (fix round 1): `UUID(123)` lanza `AttributeError`, no cubierto antes."""
    raw = _b64({"k": "occurred", "t": "2026-01-01T00:00:00+00:00", "i": 123})

    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "occurred")
    assert exc_info.value.field == "cursor"


@pytest.mark.unit
def test_sort_key_no_string_lanza_validation_error() -> None:
    raw = _b64({"k": "occurred", "t": 123, "i": str(uuid4())})

    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "occurred")
    assert exc_info.value.field == "cursor"


@pytest.mark.unit
def test_kind_no_string_lanza_validation_error() -> None:
    raw = _b64({"k": 1, "t": "2026-01-01T00:00:00+00:00", "i": str(uuid4())})

    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "occurred")
    assert exc_info.value.field == "cursor"


@pytest.mark.unit
def test_json_es_un_arreglo_lanza_validation_error() -> None:
    raw = _b64(["occurred", "2026-01-01T00:00:00+00:00", str(uuid4())])

    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "occurred")
    assert exc_info.value.field == "cursor"


@pytest.mark.unit
def test_json_es_un_string_lanza_validation_error() -> None:
    raw = _b64("solo-un-string")

    with pytest.raises(ValidationAppError) as exc_info:
        decode_cursor(raw, "occurred")
    assert exc_info.value.field == "cursor"


def _build_page_params_app() -> FastAPI:
    """App minima (sin infraestructura) solo para ejercitar la dependencia `page_params`."""
    app = FastAPI()
    install_error_handlers(app)

    @app.get("/_test/page")
    def _page(params: PageParams = Depends(page_params)) -> dict[str, object]:
        return {"limit": params.limit, "cursor": params.cursor}

    return app


@pytest.mark.unit
async def test_page_params_usa_limit_50_y_cursor_none_por_defecto() -> None:
    transport = ASGITransport(app=_build_page_params_app())
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/_test/page")

    assert response.status_code == 200
    assert response.json() == {"limit": 50, "cursor": None}


@pytest.mark.unit
@pytest.mark.parametrize("limit", [1, 200])
async def test_page_params_acepta_los_limites_de_frontera(limit: int) -> None:
    transport = ASGITransport(app=_build_page_params_app())
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/_test/page", params={"limit": limit})

    assert response.status_code == 200
    assert response.json()["limit"] == limit


@pytest.mark.unit
@pytest.mark.parametrize("limit", [0, 201])
async def test_page_params_rechaza_limit_fuera_de_rango(limit: int) -> None:
    transport = ASGITransport(app=_build_page_params_app())
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/_test/page", params={"limit": limit})

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "validation_error"
