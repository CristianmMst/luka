"""Composicion, saneamiento y validacion del cuerpo de un mensaje crudo.

Puro (stdlib solo, P3): spec 006 §2.3 (extraccion/truncado del cuerpo), §3.2
(composicion titulo+texto de notificaciones), §4.4 (formato de `external_id` por
canal, idempotencia de ingesta) y spec 004 §6 (retencion de 90 dias).
"""

from __future__ import annotations

import re
from datetime import datetime, timedelta

from luka.modules.ingestion.domain.enums import Channel
from luka.modules.ingestion.domain.errors import InvalidChannel, InvalidExternalId

_HEX64_PATTERN = re.compile(r"^[a-f0-9]{64}$")
_EXTERNAL_ID_MAX_LEN = 256


def compose_body(title: str | None, text: str) -> str:
    r"""`titulo\n\ntexto` si hay un titulo no vacio; si no, solo `texto` (spec 006 §3.2).

    El resultado siempre queda recortado (`strip`) en ambos extremos.
    """
    if title and title.strip():
        return f"{title}\n\n{text}".strip()
    return text.strip()


def truncate_utf8(s: str, max_bytes: int) -> str:
    """Trunca `s` a lo sumo `max_bytes` bytes UTF-8 sin partir un caracter multibyte
    (spec 006 §2.3). Si `s` ya cabe, se devuelve sin cambios.
    """
    encoded = s.encode("utf-8")
    if len(encoded) <= max_bytes:
        return s
    # `errors="ignore"` descarta los bytes finales de una secuencia multibyte
    # incompleta (frontera de caracter), sin agregar bytes: el resultado nunca
    # supera `max_bytes`.
    return encoded[:max_bytes].decode("utf-8", errors="ignore")


def purge_after_for(received_at: datetime, retention_days: int) -> datetime:
    """`received_at + retention_days` (spec 004 §6, purga del cuerpo a los 90 dias)."""
    return received_at + timedelta(days=retention_days)


def validate_external_id(channel: Channel, value: str) -> None:
    """Valida el formato de `external_id` segun el canal; lanza `InvalidExternalId`
    si no cumple (spec 006 §4.4).

    `notification`/`sms_notification`: hash sha256 hexadecimal en minusculas
    (`client_hash`, spec 006 §3.2). `email`: no vacio, <= 256 caracteres y sin
    espacios en blanco (Gmail message id).
    """
    if channel in (Channel.NOTIFICATION, Channel.SMS_NOTIFICATION):
        if _HEX64_PATTERN.fullmatch(value) is None:
            raise InvalidExternalId(f"external_id invalido para canal {channel.value}")
        return
    if channel is Channel.EMAIL:
        if not value or len(value) > _EXTERNAL_ID_MAX_LEN or any(c.isspace() for c in value):
            raise InvalidExternalId("external_id invalido para canal email")
        return
    raise InvalidChannel(f"canal no soportado: {channel!r}")


__all__ = ["compose_body", "purge_after_for", "truncate_utf8", "validate_external_id"]
