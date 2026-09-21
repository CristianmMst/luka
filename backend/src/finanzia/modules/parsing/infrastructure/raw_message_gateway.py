"""Gateway que satisface `RawMessageGatewayPort` delegando en `ingestion.public`
(D2, D6): unico punto por el que parsing lee/transiciona un `raw_message`, sin
importar internals de `ingestion` (R4).
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from finanzia.modules.ingestion import public as ingestion_public
from finanzia.modules.parsing.application.dto import RawMessageView

if TYPE_CHECKING:
    from datetime import datetime
    from uuid import UUID

    from sqlalchemy.ext.asyncio import AsyncSession

    # `ingestion_public.RawMessageView` (atributo del modulo ya importado arriba,
    # no un import propio a `ingestion.application.dto`): un import separado a
    # ese submodulo violaria R4 (solo `ingestion.public`/`ingestion.events` son
    # cruzables). `ingestion.public` re-exporta el mismo tipo de dataclass.
    IngestionRawMessageView = ingestion_public.RawMessageView


def _to_view(view: IngestionRawMessageView) -> RawMessageView:
    """Mapea la vista de `ingestion` (enums propios) a la de `parsing` (str, D4)."""
    return RawMessageView(
        id=view.id,
        user_id=view.user_id,
        channel=view.channel.value,
        bank=view.bank,
        sender=view.sender,
        body=view.body,
        status=view.status.value,
        received_at=view.received_at,
    )


class IngestionRawMessageGateway:
    """Implementa `RawMessageGatewayPort` sobre `ingestion.public` (D2)."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_for_parsing(self, raw_message_id: UUID) -> RawMessageView | None:
        view = await ingestion_public.get_raw_message_for_parsing(self._session, raw_message_id)
        return _to_view(view) if view is not None else None

    async def mark(self, raw_message_id: UUID, status: str, now: datetime) -> bool:
        """Idempotente (P2): marcar el mismo `status` dos veces no lanza (el
        `UPDATE` de `ingestion` no depende del estado actual de la fila).
        """
        return await ingestion_public.mark_raw_message(self._session, raw_message_id, status, now)


__all__ = ["IngestionRawMessageGateway"]
