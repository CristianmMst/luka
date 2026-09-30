"""Verificador del token OIDC de los push de Pub/Sub (spec 005 §4, spec 009 §2).

Pub/Sub firma cada push con un id_token de Google del service account de la
suscripcion, con `aud` = la audiencia configurada en la suscripcion. Se valida
firma y `exp` (`google.oauth2.id_token.verify_token`, en un hilo porque baja las
claves publicas con `requests`), `aud`, `iss`, `email` y `email_verified`.
Nunca loguea el token ni sus claims.
"""

from __future__ import annotations

import asyncio
from collections.abc import Mapping
from typing import Any

import cachecontrol
import requests
from google.auth.exceptions import GoogleAuthError
from google.auth.transport import Request as TransportRequest
from google.auth.transport.requests import Request
from google.oauth2 import id_token as google_id_token

from luka.modules.ingestion.domain.errors import InvalidPushToken

_VALID_ISSUERS = frozenset({"accounts.google.com", "https://accounts.google.com"})


class GoogleOidcPushVerifier:
    """`PushTokenVerifierPort` real contra las claves publicas de Google.

    `request` solo lo pasan los tests (un transporte que sirve certificados
    propios); por defecto es una sesion HTTP con cache de claves, construida
    una vez por proceso.
    """

    def __init__(
        self,
        *,
        audience: str,
        service_account: str,
        request: TransportRequest | None = None,
    ) -> None:
        self._audience = audience
        self._service_account = service_account
        self._request = request or Request(session=cachecontrol.CacheControl(requests.Session()))

    async def verify(self, token: str) -> None:
        try:
            claims: Mapping[str, Any] = await asyncio.to_thread(
                google_id_token.verify_token,
                token,
                self._request,
                audience=self._audience,
            )
        except (ValueError, GoogleAuthError) as exc:
            raise InvalidPushToken("firma, audiencia o vigencia invalida") from exc

        if claims.get("iss") not in _VALID_ISSUERS:
            raise InvalidPushToken("emisor invalido")
        if claims.get("email") != self._service_account:
            raise InvalidPushToken("service account inesperado")
        if claims.get("email_verified") is not True:
            raise InvalidPushToken("email del service account sin verificar")


__all__ = ["GoogleOidcPushVerifier"]
