"""Verificadores de `id_token` de Google Sign-In (spec 009 SS2.1, controller ruling 2)."""

import asyncio

import cachecontrol
import requests
from google.auth.exceptions import GoogleAuthError
from google.auth.transport.requests import Request
from google.oauth2 import id_token as google_id_token

from finanzia.modules.identity.domain.entities import GoogleIdentity
from finanzia.modules.identity.domain.errors import InvalidGoogleToken

_VALID_ISSUERS = frozenset({"accounts.google.com", "https://accounts.google.com"})

_FAKE_TOKEN_PARTS_WITH_FLAG = 4
_FAKE_TOKEN_PARTS_WITH_NAME = 5


class GoogleAuthIdTokenVerifier:
    """Verifica el `id_token` contra las claves publicas oficiales de Google."""

    def __init__(self, client_id: str) -> None:
        self._client_id = client_id
        self._request = Request(session=cachecontrol.CacheControl(requests.Session()))

    async def verify(self, id_token: str) -> GoogleIdentity:
        """Verifica firma, `aud` y `exp`; valida `iss` explicitamente."""
        try:
            claims = await asyncio.to_thread(
                google_id_token.verify_oauth2_token,
                id_token,
                self._request,
                self._client_id,
            )
        except (ValueError, GoogleAuthError) as exc:
            raise InvalidGoogleToken from exc

        if claims.get("iss") not in _VALID_ISSUERS:
            raise InvalidGoogleToken

        return GoogleIdentity(
            sub=claims["sub"],
            email=claims["email"],
            email_verified=bool(claims.get("email_verified")),
            name=claims.get("name"),
            picture=claims.get("picture"),
        )


class FakeGoogleIdTokenVerifier:
    """Doble de desarrollo: acepta tokens `fake:<sub>:<email>[:unverified[:<name>]]`.

    Solo debe cablearse cuando `settings.google_verifier == "fake"` (Settings ya
    prohibe ese valor en `env="prod"`); permite probar el flujo de login sin
    credenciales reales de Google Cloud.
    """

    async def verify(self, id_token: str) -> GoogleIdentity:
        parts = id_token.split(":")
        valid_lengths = (3, _FAKE_TOKEN_PARTS_WITH_FLAG, _FAKE_TOKEN_PARTS_WITH_NAME)
        if len(parts) not in valid_lengths or parts[0] != "fake" or not parts[1] or not parts[2]:
            raise InvalidGoogleToken

        sub, email = parts[1], parts[2]
        email_verified = True
        name = f"Usuario {sub}"

        if len(parts) >= _FAKE_TOKEN_PARTS_WITH_FLAG:
            if parts[3] != "unverified":
                raise InvalidGoogleToken
            email_verified = False

        if len(parts) == _FAKE_TOKEN_PARTS_WITH_NAME and parts[4]:
            name = parts[4]

        return GoogleIdentity(
            sub=sub,
            email=email,
            email_verified=email_verified,
            name=name,
            picture=None,
        )
