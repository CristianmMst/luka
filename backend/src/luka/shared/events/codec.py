"""Registro y (de)serializacion de eventos de dominio (spec 003 SS2.3).

`encode` produce campos string-only aptos para `XADD` (Redis Streams); `decode` los
reconstruye a partir del registro de tipos y `typing.get_type_hints` (los eventos
usan `from __future__ import annotations`, asi que sus anotaciones son strings que
hay que resolver contra el modulo donde viven).
"""

from __future__ import annotations

import dataclasses
import json
import types
import typing
from collections.abc import Callable, Mapping
from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import Any, TypeVar
from uuid import UUID

from luka.shared.events.base import event_type_of

EventT = TypeVar("EventT")

_NoneType = type(None)


class UnknownEventType(LookupError):  # noqa: N818 - nombre fijado por controller ruling (Task 14)
    """`event_type` sin clase registrada en el `EventRegistry`."""


def _json_default(value: object) -> object:
    if isinstance(value, UUID):
        return str(value)
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, Enum):
        return value.value
    msg = f"tipo no serializable en payload de evento: {type(value)!r}"
    raise TypeError(msg)


def _as_str(value: bytes | str) -> str:
    return value.decode() if isinstance(value, bytes) else value


_SIMPLE_COERCERS: dict[Any, Callable[[Any], Any]] = {
    UUID: UUID,
    Decimal: Decimal,
    datetime: datetime.fromisoformat,
    bool: bool,
    int: int,
}


def _coerce(value: Any, annotation: Any) -> Any:
    origin = typing.get_origin(annotation)
    if origin is typing.Union or origin is types.UnionType:
        if value is None:
            return None
        args = [arg for arg in typing.get_args(annotation) if arg is not _NoneType]
        annotation = args[0] if args else None

    coercer = _SIMPLE_COERCERS.get(annotation)
    if coercer is not None:
        return coercer(value)
    if isinstance(annotation, type) and issubclass(annotation, Enum):
        return annotation(value)
    return value


class EventRegistry:
    """Mapea `event_type` (str) -> clase dataclass del evento."""

    def __init__(self) -> None:
        self._by_type: dict[str, type] = {}

    def register(self, cls: type[EventT]) -> type[EventT]:
        """Registra `cls`; usable como decorador o como llamada directa.

        Registrar la misma clase dos veces bajo el mismo `event_type` es un no-op;
        registrar un `event_type` ya usado por OTRA clase levanta `ValueError`.
        """
        event_type = event_type_of(cls)
        existing = self._by_type.get(event_type)
        if existing is not None and existing is not cls:
            msg = f"event_type '{event_type}' ya registrado con otra clase: {existing!r}"
            raise ValueError(msg)
        self._by_type[event_type] = cls
        return cls

    def get(self, event_type: str) -> type:
        try:
            return self._by_type[event_type]
        except KeyError:
            raise UnknownEventType(event_type) from None

    def encode(self, event: object) -> dict[str, str]:
        """Codifica `event` a campos string aptos para `XADD`."""
        payload = dataclasses.asdict(event)  # type: ignore[call-overload]
        return {
            "event_id": str(event.event_id),  # type: ignore[attr-defined]
            "event_type": event_type_of(event),
            "occurred_at": event.occurred_at.isoformat(),  # type: ignore[attr-defined]
            "payload": json.dumps(payload, default=_json_default),
        }

    def decode(self, fields: Mapping[Any, Any]) -> object:
        """Reconstruye la instancia del evento a partir de campos de un `XADD`.

        `fields` acepta claves/valores `bytes` o `str` indistintamente (Redis con
        `decode_responses=False` devuelve bytes); se tipa `Mapping[Any, Any]` en
        vez de `Mapping[bytes | str, bytes | str]` porque `Mapping`/`dict` son
        invariantes en la clave y eso rechaza en pyright un `dict[bytes, bytes]`
        o `dict[str, str]` concretos como los que realmente llegan aqui.
        """
        decoded = {_as_str(key): _as_str(value) for key, value in fields.items()}
        cls = self.get(decoded["event_type"])
        payload: dict[str, Any] = json.loads(decoded["payload"])
        hints = typing.get_type_hints(cls)
        kwargs = {
            name: _coerce(value, hints[name]) for name, value in payload.items() if name in hints
        }
        return cls(**kwargs)


__all__ = ["EventRegistry", "UnknownEventType"]
