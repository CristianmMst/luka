"""Eventos de dominio que publica/consume ingestion. Puro: solo stdlib."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import ClassVar
from uuid import UUID


@dataclass(frozen=True, slots=True)
class RawMessageReceived:
    """Un mensaje crudo (correo o notificacion) quedo persistido como `pending`.

    Solo ids y metadatos (D2): el stream retiene ~100k entradas y la DLQ copia
    sus campos, asi que el cuerpo bancario nunca viaja aqui (P6, retencion de 90
    dias / purge). Parsing lee el cuerpo con
    `ingestion.public.get_raw_message_for_parsing(session, raw_message_id)`.
    """

    event_id: UUID
    occurred_at: datetime
    raw_message_id: UUID
    user_id: UUID
    channel: str
    bank: str | None
    received_at: datetime

    event_type: ClassVar[str] = "ingestion.RawMessageReceived"


__all__ = ["RawMessageReceived"]
