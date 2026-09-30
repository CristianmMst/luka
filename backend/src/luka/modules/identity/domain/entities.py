"""Entidades de dominio de identity: inmutables, sin dependencias externas (P3)."""

from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from uuid import UUID


class UserStatus(StrEnum):
    """Estado del ciclo de vida de un usuario."""

    ACTIVE = "active"
    DELETION_PENDING = "deletion_pending"


@dataclass(frozen=True, slots=True)
class User:
    """Usuario identificado de forma estable por `google_sub` (spec 009 SS2.1)."""

    id: UUID
    google_sub: str
    email: str
    display_name: str | None
    photo_url: str | None
    status: UserStatus
    consents: Mapping[str, datetime]
    created_at: datetime
    updated_at: datetime


@dataclass(frozen=True, slots=True)
class RefreshToken:
    """Refresh token opaco: solo se persiste su hash (spec 009 SS2.2)."""

    id: UUID
    user_id: UUID
    token_hash: str
    family_id: UUID
    expires_at: datetime
    revoked_at: datetime | None
    device_info: str | None
    created_at: datetime


@dataclass(frozen=True, slots=True)
class GoogleIdentity:
    """Identidad verificada devuelta por Google al validar el `id_token`."""

    sub: str
    email: str
    email_verified: bool
    name: str | None
    picture: str | None
