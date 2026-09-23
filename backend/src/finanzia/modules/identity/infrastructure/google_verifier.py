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

        try:
            return GoogleIdentity(
                sub=claims["sub"],
                email=claims["email"],
                email_verified=bool(claims.get("email_verified", False)),
                name=claims.get("name"),
                picture=claims.get("picture"),
            )
        except (KeyError, ValueError, GoogleAuthError) as exc:
            raise InvalidGoogleToken from exc
