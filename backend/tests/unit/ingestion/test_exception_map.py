"""Unit tests de `INGESTION_EXCEPTION_MAP` para la conexion Gmail (F3.3, spec 005 §1/§3)."""

import pytest

from finanzia.modules.ingestion.domain.errors import (
    GmailRefreshTokenMissing,
    GmailScopeNotGranted,
    GmailTokenUndecryptable,
    GmailTransientError,
    InvalidServerAuthCode,
)
from finanzia.modules.ingestion.infrastructure.api.errors import INGESTION_EXCEPTION_MAP

pytestmark = pytest.mark.unit


@pytest.mark.parametrize(
    "error", [InvalidServerAuthCode(), GmailRefreshTokenMissing("x"), GmailScopeNotGranted("x")]
)
def test_fallos_del_canje_son_400_en_server_auth_code(error: Exception) -> None:
    app_error = INGESTION_EXCEPTION_MAP[type(error)](error)

    assert (app_error.status, app_error.code, app_error.field) == (
        400,
        "validation_error",
        "server_auth_code",
    )


def test_fallo_transitorio_de_google_es_503() -> None:
    error = GmailTransientError("token: 503")

    app_error = INGESTION_EXCEPTION_MAP[GmailTransientError](error)

    assert (app_error.status, app_error.code) == (503, "upstream_unavailable")
    assert "503" not in app_error.message


def test_token_indescifrable_es_500_sin_detalles() -> None:
    # `AesGcmTokenCipher` envuelve `DecryptionError` en `GmailTokenUndecryptable`,
    # asi que `DecryptionError` no tiene entrada propia: cae en `IngestionError`.
    error = GmailTokenUndecryptable()

    app_error = INGESTION_EXCEPTION_MAP[type(error).__mro__[1]](error)

    assert GmailTokenUndecryptable not in INGESTION_EXCEPTION_MAP
    assert (app_error.status, app_error.code) == (500, "internal")
