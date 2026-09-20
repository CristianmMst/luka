"""Paginacion por cursor opaco: encode/decode + parametros de pagina (spec 005 SS1).

El cursor es JSON compacto en base64url SIN padding: `{"k": kind, "t": iso, "i": id}`.
`k` fija el orden esperado (`occurred` -> `(occurred_at DESC, id DESC)`; `updated` ->
`(updated_at ASC, id ASC)`, spec 005 SS1) para que un cursor de un listado no pueda
reutilizarse en otro con orden distinto. Cualquier cursor malformado (base64 invalido,
JSON invalido, claves faltantes, `kind` distinto al esperado, fecha naive/invalida o
UUID invalido) se traduce a `ValidationAppError(field="cursor")` (400 `validation_error`),
nunca a un 500.
"""

from __future__ import annotations

import base64
import json
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Literal
from uuid import UUID

from fastapi import Query
from pydantic import BaseModel

from finanzia.shared.errors import ValidationAppError

CursorKind = Literal["occurred", "updated"]

_DECODE_ERRORS = (ValueError, KeyError, TypeError, UnicodeDecodeError)


def encode_cursor(sort_key: datetime, id: UUID, kind: CursorKind) -> str:
    """Codifica `(sort_key, id, kind)` como cursor opaco base64url sin padding."""
    payload = {"k": kind, "t": sort_key.astimezone(UTC).isoformat(), "i": str(id)}
    raw = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")


def decode_cursor(raw: str, expected_kind: CursorKind) -> tuple[datetime, UUID]:
    """Decodifica un cursor opaco; cualquier fallo levanta `ValidationAppError`."""
    try:
        padded = raw + "=" * (-len(raw) % 4)
        decoded = base64.urlsafe_b64decode(padded.encode("ascii"))
        payload = json.loads(decoded)

        kind = payload["k"]
        if kind != expected_kind:
            message = "kind de cursor inesperado"
            raise ValueError(message)

        sort_key = datetime.fromisoformat(payload["t"])
        if sort_key.tzinfo is None or sort_key.tzinfo.utcoffset(sort_key) is None:
            message = "sort_key naive"
            raise ValueError(message)

        cursor_id = UUID(payload["i"])
    except _DECODE_ERRORS as exc:
        raise ValidationAppError(message="Cursor invalido", field="cursor") from exc

    return sort_key, cursor_id


@dataclass(frozen=True, slots=True)
class PageParams:
    """Parametros de paginacion validados: `limit` en `[1, 200]`, `cursor` opaco opcional."""

    limit: int
    cursor: str | None


def page_params(
    limit: int = Query(50, ge=1, le=200),
    cursor: str | None = Query(None, max_length=512),
) -> PageParams:
    """Dependencia FastAPI: resuelve y valida `?limit=&cursor=` (spec 005 SS1)."""
    return PageParams(limit=limit, cursor=cursor)


class Page[T](BaseModel):
    """Envoltura de respuesta paginada: `{"items": [...], "next_cursor": "..." | null}`."""

    items: list[T]
    next_cursor: str | None
