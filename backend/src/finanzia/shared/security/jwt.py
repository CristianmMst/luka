"""JWT de acceso HS256: encode/decode con claims minimos (spec 009 SS2.2).

El payload solo contiene `sub`, `iat`, `exp`, `jti` (ningun dato personal).
"""

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

import jwt as pyjwt

from finanzia.shared.errors import TokenExpiredError, UnauthorizedError

_ALGORITHM = "HS256"
_REQUIRED_CLAIMS = ["sub", "exp", "iat", "jti"]


@dataclass(frozen=True, slots=True)
class AccessClaims:
    """Claims decodificados y validados de un access token."""

    sub: uuid.UUID
    jti: uuid.UUID
    exp: datetime


def _require_aware(now: datetime) -> None:
    if now.tzinfo is None or now.tzinfo.utcoffset(now) is None:
        message = "`now` debe ser un datetime aware (con tzinfo UTC)"
        raise ValueError(message)


def encode_access_token(
    *,
    user_id: uuid.UUID,
    now: datetime,
    ttl: timedelta,
    secret: str,
    jti: uuid.UUID | None = None,
) -> str:
    """Genera un access token HS256 con claims exactos `sub, iat, exp, jti`."""
    _require_aware(now)

    payload = {
        "sub": str(user_id),
        "iat": int(now.timestamp()),
        "exp": int((now + ttl).timestamp()),
        "jti": str(jti or uuid.uuid4()),
    }
    return pyjwt.encode(payload, secret, algorithm=_ALGORITHM)


def decode_access_token(token: str, secret: str) -> AccessClaims:
    """Decodifica y valida un access token HS256.

    Lanza `TokenExpiredError` si el token vencio, o `UnauthorizedError` para
    cualquier otro problema (firma invalida, algoritmo distinto, claims
    faltantes o con formato invalido).
    """
    try:
        payload = pyjwt.decode(
            token,
            secret,
            algorithms=[_ALGORITHM],
            options={"require": _REQUIRED_CLAIMS},
            leeway=0,
        )
        return AccessClaims(
            sub=uuid.UUID(payload["sub"]),
            jti=uuid.UUID(payload["jti"]),
            exp=datetime.fromtimestamp(payload["exp"], tz=UTC),
        )
    except pyjwt.ExpiredSignatureError as exc:
        raise TokenExpiredError from exc
    except (pyjwt.PyJWTError, ValueError, KeyError) as exc:
        raise UnauthorizedError from exc
