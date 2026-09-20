"""Logica pura de sesiones: hashing, rotacion y deteccion de reuso (spec 009 SS2.2)."""

import hashlib
from dataclasses import replace
from datetime import datetime, timedelta
from enum import Enum, auto
from uuid import UUID

from finanzia.modules.identity.domain.entities import RefreshToken


def hash_refresh_token(raw: str) -> str:
    """Digest SHA-256 (hex, 64 caracteres minusculas) del refresh token en claro."""
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


class RefreshDecision(Enum):
    """Resultado de evaluar un refresh token candidato contra el estado guardado."""

    OK = auto()
    UNKNOWN = auto()
    REUSED = auto()
    EXPIRED = auto()


def _require_aware(now: datetime) -> None:
    if now.tzinfo is None or now.tzinfo.utcoffset(now) is None:
        raise ValueError("now debe ser un datetime con tz-aware (aware datetime)")


def is_revoked(token: RefreshToken) -> bool:
    """`True` si el token ya fue revocado (rotado, reusado o cerrado sesion)."""
    return token.revoked_at is not None


def is_expired(token: RefreshToken, now: datetime) -> bool:
    """`True` si `now` alcanzo o supero el vencimiento del token."""
    _require_aware(now)
    return token.expires_at <= now


def evaluate_refresh(token: RefreshToken | None, now: datetime) -> RefreshDecision:
    """Clasifica un refresh token candidato: UNKNOWN, REUSED, EXPIRED u OK.

    Orden de evaluacion (spec 009 SS2.2, AC-1.4): primero se busca el token; si no
    existe es UNKNOWN. Si existe pero ya esta revocado (fue rotado o cerrado), es un
    reuso: REUSED. Si no esta revocado pero vencio, EXPIRED. En cualquier otro caso,
    OK.
    """
    _require_aware(now)
    if token is None:
        return RefreshDecision.UNKNOWN
    if is_revoked(token):
        return RefreshDecision.REUSED
    if is_expired(token, now):
        return RefreshDecision.EXPIRED
    return RefreshDecision.OK


def new_family(  # noqa: PLR0913 - un campo por atributo inmutable de RefreshToken
    *,
    id: UUID,
    user_id: UUID,
    token_hash: str,
    family_id: UUID,
    now: datetime,
    ttl: timedelta,
    device_info: str | None,
) -> RefreshToken:
    """Crea el primer refresh token de una nueva familia (login)."""
    _require_aware(now)
    return RefreshToken(
        id=id,
        user_id=user_id,
        token_hash=token_hash,
        family_id=family_id,
        expires_at=now + ttl,
        revoked_at=None,
        device_info=device_info,
        created_at=now,
    )


def rotate(
    token: RefreshToken,
    *,
    now: datetime,
    new_id: UUID,
    new_hash: str,
    ttl: timedelta,
) -> tuple[RefreshToken, RefreshToken]:
    """Rota `token`: devuelve `(anterior_revocado, nuevo)` con TTL deslizante.

    El nuevo token conserva `family_id`, `user_id` y `device_info` del anterior; su
    `expires_at` es `now + ttl` (TTL deslizante de 60 dias, spec 009 SS2.2).
    """
    _require_aware(now)
    old_revoked = replace(token, revoked_at=now)
    new_token = RefreshToken(
        id=new_id,
        user_id=token.user_id,
        token_hash=new_hash,
        family_id=token.family_id,
        expires_at=now + ttl,
        revoked_at=None,
        device_info=token.device_info,
        created_at=now,
    )
    return old_revoked, new_token
