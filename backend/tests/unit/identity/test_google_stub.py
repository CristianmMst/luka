"""Unit tests del parseo de `StubGoogleIdTokenVerifier`, compartido por la suite."""

import pytest
from support.google_stub import StubGoogleIdTokenVerifier

from luka.modules.identity.domain.errors import InvalidGoogleToken


@pytest.fixture
def verifier() -> StubGoogleIdTokenVerifier:
    return StubGoogleIdTokenVerifier()


@pytest.mark.unit
async def test_token_basico_verifica_email_por_defecto(
    verifier: StubGoogleIdTokenVerifier,
) -> None:
    identity = await verifier.verify("stub:sub-1:ana@example.com")

    assert identity.sub == "sub-1"
    assert identity.email == "ana@example.com"
    assert identity.email_verified is True
    assert identity.name == "Usuario sub-1"
    assert identity.picture is None


@pytest.mark.unit
async def test_token_unverified_marca_email_no_verificado(
    verifier: StubGoogleIdTokenVerifier,
) -> None:
    identity = await verifier.verify("stub:sub-2:x@y.com:unverified")

    assert identity.email_verified is False


@pytest.mark.unit
async def test_token_con_quinto_segmento_usa_nombre_explicito(
    verifier: StubGoogleIdTokenVerifier,
) -> None:
    identity = await verifier.verify("stub:sub-3:carlos@example.com:unverified:Carlos")

    assert identity.name == "Carlos"
    assert identity.email_verified is False


@pytest.mark.unit
@pytest.mark.parametrize(
    "raw",
    [
        "nope",
        "not-a-google-token-at-all",
        "stub:solo-sub",
        "stub::sin-sub@example.com",
        "stub:sub:email@example.com:no-es-unverified",
        "google:sub:email@example.com",
    ],
)
async def test_tokens_invalidos_lanzan_invalid_google_token(
    verifier: StubGoogleIdTokenVerifier, raw: str
) -> None:
    with pytest.raises(InvalidGoogleToken):
        await verifier.verify(raw)
