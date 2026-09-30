"""Unit tests de `EXCEPTION_MAP`: todos los errores de dominio degradan a 401."""

from uuid import uuid4

import pytest

from luka.modules.identity.domain.errors import (
    EmailNotVerified,
    IdentityError,
    InvalidGoogleToken,
    RefreshTokenExpired,
    RefreshTokenInvalid,
    RefreshTokenReused,
    UserNotFound,
)
from luka.modules.identity.infrastructure.api.errors import EXCEPTION_MAP
from luka.shared.errors import UnauthorizedError

_ERRORS: list[IdentityError] = [
    InvalidGoogleToken(),
    EmailNotVerified(),
    RefreshTokenInvalid(),
    RefreshTokenReused(uuid4()),
    RefreshTokenExpired(),
    UserNotFound(),
]


@pytest.mark.unit
@pytest.mark.parametrize("error", _ERRORS, ids=lambda e: type(e).__name__)
def test_todos_los_errores_de_dominio_mapean_a_unauthorized(error: IdentityError) -> None:
    converter = EXCEPTION_MAP[type(error)]

    app_error = converter(error)

    assert isinstance(app_error, UnauthorizedError)
    assert app_error.status == 401
    assert app_error.code == "unauthorized"


@pytest.mark.unit
def test_exception_map_cubre_exactamente_los_seis_errores() -> None:
    assert set(EXCEPTION_MAP) == {type(error) for error in _ERRORS}
