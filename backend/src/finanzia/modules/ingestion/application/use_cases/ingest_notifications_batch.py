"""Caso de uso: ingesta de un batch de notificaciones/SMS (spec 006 §3.2, F4.3)."""

from collections.abc import Sequence
from uuid import UUID

from finanzia.modules.ingestion.application.dto import (
    Accepted,
    BatchResult,
    Duplicate,
    NotificationItemInput,
    RawMessageInput,
)
from finanzia.modules.ingestion.application.use_cases.ingest_raw_message import IngestRawMessage


class IngestNotificationsBatch:
    """Ingesta cada item del batch via `IngestRawMessage`.

    Un commit por item (dentro de `IngestRawMessage.execute`) para que un item
    invalido no anule el resto del batch.
    """

    def __init__(self, *, ingest: IngestRawMessage) -> None:
        self._ingest = ingest

    async def execute(self, user_id: UUID, items: Sequence[NotificationItemInput]) -> BatchResult:
        accepted = duplicates = discarded = 0
        for item in items:
            outcome = await self._ingest.execute(
                RawMessageInput(
                    user_id=user_id,
                    channel=item.channel,
                    external_id=item.client_hash,
                    sender=item.package,
                    title=item.title,
                    text=item.text,
                    received_at=item.posted_at,
                )
            )
            if isinstance(outcome, Accepted):
                accepted += 1
            elif isinstance(outcome, Duplicate):
                duplicates += 1
            else:
                discarded += 1
        return BatchResult(accepted=accepted, duplicates=duplicates, discarded=discarded)


__all__ = ["IngestNotificationsBatch"]
