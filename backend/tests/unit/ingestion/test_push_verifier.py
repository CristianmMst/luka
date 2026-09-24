"""Tests del verificador OIDC de los push de Pub/Sub (F3.4, spec 005 §4).

Tokens RS256 reales firmados con una llave de prueba (`support.oidc`): se ejercita
`google.oauth2.id_token.verify_token` completo, sin red.
"""

from dataclasses import replace
from datetime import timedelta

import pytest
from support.oidc import PushClaims, build_test_push_verifier, sign_push_token

from finanzia.modules.ingestion.domain.errors import InvalidPushToken

pytestmark = pytest.mark.unit


async def test_token_valido_pasa() -> None:
    await build_test_push_verifier().verify(sign_push_token())


@pytest.mark.parametrize("iss", ["accounts.google.com", "https://accounts.google.com"])
async def test_acepta_los_dos_emisores_de_google(iss: str) -> None:
    await build_test_push_verifier().verify(sign_push_token(PushClaims(iss=iss)))


@pytest.mark.parametrize(
    "claims",
    [
        replace(PushClaims(), aud="otra-audiencia"),
        replace(PushClaims(), email="intruso@otro-proyecto.iam.gserviceaccount.com"),
        replace(PushClaims(), email_verified=False),
        replace(PushClaims(), iss="https://evil.example.com"),
        replace(PushClaims(), expires_in=timedelta(minutes=-10)),
    ],
    ids=["otra_audiencia", "otro_email", "email_sin_verificar", "otro_emisor", "expirado"],
)
async def test_token_invalido_lanza_invalid_push_token(claims: PushClaims) -> None:
    with pytest.raises(InvalidPushToken):
        await build_test_push_verifier().verify(sign_push_token(claims))


@pytest.mark.parametrize("token", ["", "no-es-un-jwt", "a.b.c"])
async def test_token_ilegible_lanza_invalid_push_token(token: str) -> None:
    with pytest.raises(InvalidPushToken):
        await build_test_push_verifier().verify(token)


async def test_firma_alterada_lanza_invalid_push_token() -> None:
    header, payload, signature = sign_push_token().split(".")
    tampered = f"{header}.{payload}.{signature[:-4]}AAAA"

    with pytest.raises(InvalidPushToken):
        await build_test_push_verifier().verify(tampered)
