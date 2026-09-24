"""Aviso push de Gmail via Pub/Sub (spec 005 §4, F3.4). Puro (stdlib, P3).

Pub/Sub entrega un envelope JSON `{"message": {"data": <base64>, ...}, ...}`;
`data` decodifica a `{"emailAddress": ..., "historyId": ...}`. Nada de esto se
loguea: el email identifica al usuario (spec 009 §5).
"""

from __future__ import annotations

import base64
import binascii
import json
from dataclasses import dataclass
from typing import Any, cast

from finanzia.modules.ingestion.domain.errors import InvalidPushEnvelope


@dataclass(frozen=True, slots=True)
class GmailPushNotification:
    """Contenido de un aviso: la cuenta Gmail que cambio y su `historyId` actual."""

    email_address: str
    history_id: int


def _b64decode(data: str) -> bytes:
    """Base64 estandar o url-safe, con o sin padding (Pub/Sub usa el estandar)."""
    padded = data + "=" * (-len(data) % 4)
    return base64.b64decode(padded.replace("-", "+").replace("_", "/"), validate=True)


def _parse_json(raw: bytes) -> object:
    try:
        return cast("object", json.loads(raw))
    except (ValueError, UnicodeDecodeError) as exc:
        raise InvalidPushEnvelope("json invalido") from exc


def _field(container: object, key: str) -> object:
    """`container[key]` si `container` es un objeto JSON; `None` si no."""
    if not isinstance(container, dict):
        return None
    return cast("dict[str, Any]", container).get(key)


def _history_id(value: object) -> int:
    if isinstance(value, bool):
        raise InvalidPushEnvelope("historyId invalido")
    if isinstance(value, int):
        history_id = value
    elif isinstance(value, str) and value.isdigit():
        history_id = int(value)
    else:
        raise InvalidPushEnvelope("historyId invalido")
    if history_id <= 0:
        raise InvalidPushEnvelope("historyId invalido")
    return history_id


def decode_push_envelope(raw: bytes) -> GmailPushNotification:
    """Decodifica el cuerpo del push; `InvalidPushEnvelope` ante cualquier forma inesperada."""
    data = _field(_field(_parse_json(raw), "message"), "data")
    if not isinstance(data, str):
        raise InvalidPushEnvelope("envelope sin message.data")
    try:
        decoded = _b64decode(data)
    except (binascii.Error, ValueError) as exc:
        raise InvalidPushEnvelope("message.data no es base64") from exc
    payload = _parse_json(decoded)
    if not isinstance(payload, dict):
        raise InvalidPushEnvelope("message.data no es un objeto")
    payload = cast("dict[str, Any]", payload)
    email_address = _field(payload, "emailAddress")
    if not isinstance(email_address, str) or not email_address:
        raise InvalidPushEnvelope("emailAddress invalido")
    return GmailPushNotification(email_address, _history_id(_field(payload, "historyId")))


__all__ = ["GmailPushNotification", "decode_push_envelope"]
