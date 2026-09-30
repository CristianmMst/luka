"""Caso de uso: marcar el estado de un `raw_message` (F2.4/F3, parsing/revision).

No comitea: el llamador (parsing, ledger via `ingestion.public`) controla la
transaccion junto con el resto de sus cambios (D8: publish antes del commit).
"""

from datetime import datetime
from uuid import UUID

from luka.modules.ingestion.application.ports import RawMessageRepositoryPort
from luka.modules.ingestion.domain.enums import RawMessageStatus


class MarkRawMessage:
    """Delega en `RawMessageRepositoryPort.set_status`."""

    def __init__(self, *, repo: RawMessageRepositoryPort) -> None:
        self._repo = repo

    async def execute(self, id: UUID, status: RawMessageStatus, now: datetime) -> bool:
        return await self._repo.set_status(id, status, now)


__all__ = ["MarkRawMessage"]
