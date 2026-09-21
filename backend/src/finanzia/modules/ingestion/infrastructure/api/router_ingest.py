"""Router HTTP de ingestion: `POST /ingest/notifications` (spec 006 §3.2, F4.3)."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends

from finanzia.modules.ingestion.application.dto import NotificationItemInput
from finanzia.modules.ingestion.domain.enums import Channel
from finanzia.modules.ingestion.infrastructure.api.deps import (
    IngestBatchRunner,
    get_current_user_id,
    get_ingest_batch_runner,
)
from finanzia.modules.ingestion.infrastructure.api.schemas import (
    IngestNotificationsRequest,
    IngestNotificationsResponse,
)

router = APIRouter(
    prefix="/ingest", tags=["ingestion"], dependencies=[Depends(get_current_user_id)]
)


@router.post("/notifications")
async def ingest_notifications(
    body: IngestNotificationsRequest,
    user_id: UUID = Depends(get_current_user_id),
    runner: IngestBatchRunner = Depends(get_ingest_batch_runner),
) -> IngestNotificationsResponse:
    """Ingesta un batch de notificaciones/SMS Android (spec 006 §3.2).

    El servidor re-valida remitente/paquete contra el allowlist de `parsing`
    (AC-3.3): un item con paquete no soportado se descarta sin persistir, aunque
    el cliente lo haya enviado igual. No logea el contenido del request (P1/P8):
    `ingestion.public` ya emite la metrica agregada por item (`log_ingest_outcome`).
    """
    items = [
        NotificationItemInput(
            package=item.package,
            channel=Channel(item.channel),
            posted_at=item.posted_at,
            title=item.title,
            text=item.text,
            client_hash=item.client_hash,
        )
        for item in body.items
    ]
    result = await runner.run(user_id, items)
    return IngestNotificationsResponse(
        accepted=result.accepted, duplicates=result.duplicates, discarded=result.discarded
    )


__all__ = ["router"]
