"""Unit tests de `GoogleAuthIdTokenVerifier` y su cableado como singleton (review final, item D)."""

from typing import Any

import pytest
from asgi_lifespan import LifespanManager
from google.auth.exceptions import GoogleAuthError
from support.settings import GOOGLE_SETTINGS, TEST_GOOGLE_CLIENT_ID, TEST_GOOGLE_IOS_CLIENT_ID

from luka.app import create_app
from luka.modules.identity.domain.errors import InvalidGoogleToken
from luka.modules.identity.infrastructure.api.deps import get_google_verifier
from luka.modules.identity.infrastructure.google_verifier import GoogleAuthIdTokenVerifier
from luka.shared.settings import Settings

_VALID_CLAIMS: dict[str, Any] = {
    "iss": "accounts.google.com",
    "sub": "sub-123",
    "email": "ana@example.com",
    "email_verified": True,
    "name": "Ana",
    "picture": "https://example.com/ana.png",
}


@pytest.fixture
def verifier() -> GoogleAuthIdTokenVerifier:
    return GoogleAuthIdTokenVerifier(audiences=("test-client",))


@pytest.mark.unit
async def test_claims_validos_devuelve_google_identity(
    monkeypatch: pytest.MonkeyPatch, verifier: GoogleAuthIdTokenVerifier
) -> None:
    monkeypatch.setattr(
        "luka.modules.identity.infrastructure.google_verifier.google_id_token.verify_oauth2_token",
        lambda *_args, **_kwargs: dict(_VALID_CLAIMS),
    )

    identity = await verifier.verify("token")

    assert identity.sub == "sub-123"
    assert identity.email == "ana@example.com"
    assert identity.email_verified is True
    assert identity.name == "Ana"
    assert identity.picture == "https://example.com/ana.png"


@pytest.mark.unit
async def test_acepta_el_cliente_web_y_el_de_ios(monkeypatch: pytest.MonkeyPatch) -> None:
    """En iOS el `id_token` llega con `aud` = cliente iOS, no el web (Android):
    el backend debe aceptar ambos (spec 009 SS2.1)."""
    seen: list[object] = []

    def _verify(_token: str, _request: object, audience: object) -> dict[str, Any]:
        seen.append(audience)
        return dict(_VALID_CLAIMS)

    monkeypatch.setattr(
        "luka.modules.identity.infrastructure.google_verifier.google_id_token.verify_oauth2_token",
        _verify,
    )

    await GoogleAuthIdTokenVerifier(audiences=("web-client", "ios-client")).verify("token")

    assert seen == [["web-client", "ios-client"]]


@pytest.mark.unit
async def test_issuer_invalido_lanza_invalid_google_token(
    monkeypatch: pytest.MonkeyPatch, verifier: GoogleAuthIdTokenVerifier
) -> None:
    bad_claims = {**_VALID_CLAIMS, "iss": "https://evil.example.com"}
    monkeypatch.setattr(
        "luka.modules.identity.infrastructure.google_verifier.google_id_token.verify_oauth2_token",
        lambda *_args, **_kwargs: bad_claims,
    )

    with pytest.raises(InvalidGoogleToken):
        await verifier.verify("token")


@pytest.mark.unit
async def test_value_error_de_la_libreria_lanza_invalid_google_token(
    monkeypatch: pytest.MonkeyPatch, verifier: GoogleAuthIdTokenVerifier
) -> None:
    def _raise(*_args: object, **_kwargs: object) -> dict[str, Any]:
        raise ValueError("firma invalida")

    monkeypatch.setattr(
        "luka.modules.identity.infrastructure.google_verifier.google_id_token.verify_oauth2_token",
        _raise,
    )

    with pytest.raises(InvalidGoogleToken):
        await verifier.verify("token")


@pytest.mark.unit
async def test_google_auth_error_de_la_libreria_lanza_invalid_google_token(
    monkeypatch: pytest.MonkeyPatch, verifier: GoogleAuthIdTokenVerifier
) -> None:
    def _raise(*_args: object, **_kwargs: object) -> dict[str, Any]:
        raise GoogleAuthError("no se pudieron obtener las claves publicas")

    monkeypatch.setattr(
        "luka.modules.identity.infrastructure.google_verifier.google_id_token.verify_oauth2_token",
        _raise,
    )

    with pytest.raises(InvalidGoogleToken):
        await verifier.verify("token")


@pytest.mark.unit
async def test_claims_sin_email_lanza_invalid_google_token(
    monkeypatch: pytest.MonkeyPatch, verifier: GoogleAuthIdTokenVerifier
) -> None:
    claims_sin_email = {k: v for k, v in _VALID_CLAIMS.items() if k != "email"}
    monkeypatch.setattr(
        "luka.modules.identity.infrastructure.google_verifier.google_id_token.verify_oauth2_token",
        lambda *_args, **_kwargs: claims_sin_email,
    )

    with pytest.raises(InvalidGoogleToken):
        await verifier.verify("token")


@pytest.mark.unit
async def test_claims_sin_sub_lanza_invalid_google_token(
    monkeypatch: pytest.MonkeyPatch, verifier: GoogleAuthIdTokenVerifier
) -> None:
    claims_sin_sub = {k: v for k, v in _VALID_CLAIMS.items() if k != "sub"}
    monkeypatch.setattr(
        "luka.modules.identity.infrastructure.google_verifier.google_id_token.verify_oauth2_token",
        lambda *_args, **_kwargs: claims_sin_sub,
    )

    with pytest.raises(InvalidGoogleToken):
        await verifier.verify("token")


@pytest.mark.unit
async def test_email_verified_ausente_se_normaliza_a_false(
    monkeypatch: pytest.MonkeyPatch, verifier: GoogleAuthIdTokenVerifier
) -> None:
    claims_sin_flag = {k: v for k, v in _VALID_CLAIMS.items() if k != "email_verified"}
    monkeypatch.setattr(
        "luka.modules.identity.infrastructure.google_verifier.google_id_token.verify_oauth2_token",
        lambda *_args, **_kwargs: claims_sin_flag,
    )

    identity = await verifier.verify("token")

    assert identity.email_verified is False


class _FakeRequest:
    """Doble minimo de `fastapi.Request`: solo expone `.app` (lo que usa la dependencia)."""

    def __init__(self, app: object) -> None:
        self.app = app


@pytest.mark.unit
async def test_google_verifier_es_el_mismo_objeto_en_dos_requests() -> None:
    """El verificador se construye una unica vez en el lifespan (no por request)."""
    settings = Settings(
        _env_file=None,  # pyright: ignore[reportCallIssue]
        env="test",
        database_url="postgresql+asyncpg://luka:luka@localhost:5432/luka_test_unused",
        redis_url="redis://localhost:6379/1",
        jwt_secret="test-secret-test-secret-test-secret-1234",
        **GOOGLE_SETTINGS,
        google_client_secret="test-google-client-secret",
        gmail_token_key="AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE=",
    )
    app = create_app(settings)

    async with LifespanManager(app):
        first = get_google_verifier(_FakeRequest(app))  # type: ignore[arg-type]
        second = get_google_verifier(_FakeRequest(app))  # type: ignore[arg-type]

    assert first is second
    assert isinstance(first, GoogleAuthIdTokenVerifier)
    assert first.audiences == (TEST_GOOGLE_CLIENT_ID, TEST_GOOGLE_IOS_CLIENT_ID)
