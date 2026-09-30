"""Generador de identificadores y refresh tokens opacos (spec 009 SS2.2)."""

import secrets
import uuid

_REFRESH_TOKEN_BYTES = 32


class SecretsTokenGenerator:
    """Implementacion de `TokenGeneratorPort` basada en `secrets`/`uuid`."""

    def new_refresh_token(self) -> str:
        return secrets.token_urlsafe(_REFRESH_TOKEN_BYTES)

    def new_id(self) -> uuid.UUID:
        return uuid.uuid4()
