"""Unit tests del parseo de `FakeGoogleIdTokenVerifier` (controller ruling 2)."""

import pytest

from finanzia.modules.identity.domain.errors import InvalidGoogleToken
from finanzia.modules.identity.infrastructure.google_verifier import FakeGoogleIdTokenVerifier


@pytest.fixture
def verifier() -> FakeGoogleIdTokenVerifier:
    return FakeGoogleIdTokenVerifier()


@pytest.mark.unit
async def test_token_basico_verifica_email_por_defecto(
    verifier: FakeGoogleIdTokenVerifier,
) -> None:
    identity = await verifier.verify("fake:sub-1:ana@example.com")

    assert identity.sub == "sub-1"
    assert identity.email == "ana@example.com"
    assert identity.email_verified is True
    assert identity.name == "Usuario sub-1"
    assert identity.picture is None


@pytest.mark.unit
async def test_token_unverified_marca_email_no_verificado(
    verifier: FakeGoogleIdTokenVerifier,
) -> None:
    identity = await verifier.verify("fake:sub-2:x@y.com:unverified")

    assert identity.email_verified is False


@pytest.mark.unit
async def test_token_con_quinto_segmento_usa_nombre_explicito(
    verifier: FakeGoogleIdTokenVerifier,
) -> None:
    identity = await verifier.verify("fake:sub-3:carlos@example.com:unverified:Carlos")

    assert identity.name == "Carlos"
    assert identity.email_verified is False


@pytest.mark.unit
@pytest.mark.parametrize(
    "raw",
    [
        "nope",
        "not-a-google-token-at-all",
        "fake:solo-sub",
        "fake::sin-sub@example.com",
        "fake:sub:email@example.com:no-es-unverified",
        "google:sub:email@example.com",
    ],
)
async def test_tokens_invalidos_lanzan_invalid_google_token(
    verifier: FakeGoogleIdTokenVerifier, raw: str
) -> None:
    with pytest.raises(InvalidGoogleToken):
        await verifier.verify(raw)
