"""Verificador de Google para tests: no llama a Google (spec 009 SS2.1).

La app de produccion no tiene modo simulado; los tests inyectan este stub con
`create_app(settings, google_verifier=...)`. Acepta tokens
`stub:<sub>:<email>[:unverified[:<nombre>]]`.
"""

from fastapi import FastAPI

from finanzia.app import create_app
from finanzia.modules.identity.domain.entities import GoogleIdentity
from finanzia.modules.identity.domain.errors import InvalidGoogleToken
from finanzia.modules.ingestion.application.ports import GmailClientPort
from finanzia.shared.settings import Settings

_PARTS_WITH_FLAG = 4
_PARTS_WITH_NAME = 5


class StubGoogleIdTokenVerifier:
    """Traduce un token `stub:...` a una `GoogleIdentity` sin red."""

    async def verify(self, id_token: str) -> GoogleIdentity:
        parts = id_token.split(":")
        valid_lengths = (3, _PARTS_WITH_FLAG, _PARTS_WITH_NAME)
        if len(parts) not in valid_lengths or parts[0] != "stub" or not parts[1] or not parts[2]:
            raise InvalidGoogleToken

        sub, email = parts[1], parts[2]
        email_verified = True
        name = f"Usuario {sub}"

        if len(parts) >= _PARTS_WITH_FLAG:
            if parts[3] != "unverified":
                raise InvalidGoogleToken
            email_verified = False

        if len(parts) == _PARTS_WITH_NAME and parts[4]:
            name = parts[4]

        return GoogleIdentity(
            sub=sub,
            email=email,
            email_verified=email_verified,
            name=name,
            picture=None,
        )


def create_test_app(settings: Settings, *, gmail_client: GmailClientPort | None = None) -> FastAPI:
    """`create_app` con el verificador stub cableado en el lifespan.

    `gmail_client` permite inyectar un doble de Gmail (p. ej. `GoogleGmailClient`
    sobre `httpx.MockTransport`); sin el, la app arma el cliente real, que no
    llama a Google mientras ningun test toque `/v1/gmail/*`.
    """
    return create_app(
        settings, google_verifier=StubGoogleIdTokenVerifier(), gmail_client=gmail_client
    )
