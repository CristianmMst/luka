"""Emisor del access JWT de corta duracion (envoltorio de `shared.security.jwt`)."""

from datetime import datetime, timedelta
from uuid import UUID

from luka.shared.security import encode_access_token


class JwtAccessTokenIssuer:
    """Implementacion de `AccessTokenIssuerPort`: HS256 con TTL fijo."""

    def __init__(self, secret: str, ttl: timedelta) -> None:
        self._secret = secret
        self._ttl = ttl

    def issue(self, user_id: UUID, now: datetime) -> tuple[str, int]:
        token = encode_access_token(user_id=user_id, now=now, ttl=self._ttl, secret=self._secret)
        return token, int(self._ttl.total_seconds())
