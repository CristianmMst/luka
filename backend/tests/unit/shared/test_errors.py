"""Tests unitarios de las excepciones de aplicacion (spec 005 SS1)."""

from collections.abc import Callable

import pytest

from luka.shared.errors import (
    AppError,
    ConflictError,
    ForbiddenError,
    InternalError,
    NotFoundError,
    RateLimitedError,
    TokenExpiredError,
    UnauthorizedError,
    ValidationAppError,
)


@pytest.mark.unit
@pytest.mark.parametrize(
    ("error_class", "expected_status", "expected_code"),
    [
        (ValidationAppError, 400, "validation_error"),
        (UnauthorizedError, 401, "unauthorized"),
        (TokenExpiredError, 401, "token_expired"),
        (ForbiddenError, 403, "forbidden"),
        (NotFoundError, 404, "not_found"),
        (ConflictError, 409, "conflict"),
        (InternalError, 500, "internal"),
    ],
)
def test_subclase_expone_status_y_code_esperados(
    error_class: Callable[[], AppError], expected_status: int, expected_code: str
) -> None:
    error = error_class()

    assert error.status == expected_status
    assert error.code == expected_code
    assert error.field is None
    assert error.headers == {}
    assert error.reason is None


@pytest.mark.unit
def test_validation_app_error_acepta_un_reason_estable() -> None:
    error = ValidationAppError(message="x", field="server_auth_code", reason="invalid_code")

    assert (error.status, error.code, error.field, error.reason) == (
        400,
        "validation_error",
        "server_auth_code",
        "invalid_code",
    )


@pytest.mark.unit
def test_rate_limited_error_agrega_retry_after_header() -> None:
    error = RateLimitedError(retry_after=7)

    assert error.status == 429
    assert error.code == "rate_limited"
    assert error.headers == {"Retry-After": "7"}
    assert error.field is None


@pytest.mark.unit
def test_app_error_acepta_mensaje_y_field_personalizados() -> None:
    error = NotFoundError(message="cuenta no encontrada", field="account_id")

    assert error.message == "cuenta no encontrada"
    assert error.field == "account_id"


@pytest.mark.unit
def test_app_error_base_expone_atributos_directamente() -> None:
    error = AppError(status=418, code="teapot", message="soy una tetera")

    assert error.status == 418
    assert error.code == "teapot"
    assert error.field is None
    assert error.headers == {}
