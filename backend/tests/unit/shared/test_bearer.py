"""Tests unitarios del parser estricto de header `Authorization: Bearer` (spec 005 SS1)."""

import pytest

from luka.shared.errors import UnauthorizedError
from luka.shared.security import bearer_token


@pytest.mark.unit
def test_header_valido_devuelve_el_token() -> None:
    assert bearer_token("Bearer abc123") == "abc123"


@pytest.mark.unit
@pytest.mark.parametrize(
    "authorization",
    [
        None,
        "",
        "Basic xyz",
        "bearer x",
        "Bearer",
        "Bearer a b",
        "Bearer  x",
        "Bearer abc\tdef",
        "Bearer abc\ndef",
        "Bearer abc\rdef",
        "Bearer abc ",
    ],
)
def test_headers_invalidos_lanzan_unauthorized_error(authorization: str | None) -> None:
    with pytest.raises(UnauthorizedError):
        bearer_token(authorization)
