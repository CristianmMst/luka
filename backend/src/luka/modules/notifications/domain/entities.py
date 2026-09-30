"""Entidades de notifications: token de dispositivo y mensaje push (spec 004 SS2.15, 011 SS5)."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from enum import StrEnum
from uuid import UUID

TOKEN_MAX = 4096


class Platform(StrEnum):
    """Plataforma del dispositivo que registro el token."""

    ANDROID = "android"
    IOS = "ios"


class SendOutcome(StrEnum):
    """Resultado de enviar un push a un token.

    `retryable` (red, 429, 5xx) no aparece aqui: el adapter lanza
    `PushUnavailable` para que el bus reintente el evento completo.
    """

    SENT = "sent"
    UNREGISTERED = "unregistered"


@dataclass(frozen=True, slots=True)
class DeviceToken:
    """Destino de push de un usuario (spec 004 SS2.15)."""

    id: UUID
    user_id: UUID
    token: str
    platform: Platform
    created_at: datetime
    last_seen_at: datetime


@dataclass(frozen=True, slots=True)
class PushMessage:
    """Aviso a mostrar: titulo, cuerpo y `data` para el deep link."""

    title: str
    body: str
    data: dict[str, str] = field(default_factory=dict[str, str])
