"""Caso de uso: reencolado de mensajes `pending` huerfanos (riesgo 4, cron cada 15 min).

Mitiga la falta de outbox (spec 003 §2.3, D9): si el commit de `insert_if_absent`
tuvo exito pero la publicacion de `RawMessageReceived` fallo (o se perdio en el
worker antes de procesarla), la fila queda `pending` para siempre sin este cron.
Republica el evento para toda fila `pending` cuyo `updated_at` sea mas viejo que
`older_than` (10 min por defecto le da margen al camino feliz: ingesta -> publish
-> consumo por `parsing` antes de considerarla huerfana) y le actualiza
`updated_at` (`touch`) para no volver a republicarla en la misma ventana.
"""

from __future__ import annotations

from datetime import timedelta
from typing import TYPE_CHECKING

from finanzia.modules.ingestion.events import RawMessageReceived

if TYPE_CHECKING:
    from finanzia.modules.ingestion.application.ports import (
        ClockPort,
        EventPublisherPort,
        IdGeneratorPort,
        RawMessageRepositoryPort,
        UnitOfWorkPort,
    )

_OLDER_THAN_DEFAULT = timedelta(minutes=10)
_LIMIT_DEFAULT = 500


class RequeuePendingRawMessages:
    """Republica `RawMessageReceived` para filas `pending` con `updated_at` vencido."""

    def __init__(
        self,
        *,
        repo: RawMessageRepositoryPort,
        events: EventPublisherPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._repo = repo
        self._events = events
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(
        self,
        *,
        older_than: timedelta = _OLDER_THAN_DEFAULT,
        limit: int = _LIMIT_DEFAULT,
    ) -> int:
        now = self._clock.now()
        before = now - older_than
        rows = await self._repo.list_pending_older_than(before, limit)

        for row in rows:
            await self._events.publish(
                RawMessageReceived(
                    event_id=self._ids.new_id(),
                    occurred_at=now,
                    raw_message_id=row.id,
                    user_id=row.user_id,
                    channel=row.channel.value,
                    bank=row.bank,
                    received_at=row.received_at,
                )
            )
            await self._repo.touch(row.id, now)

        await self._uow.commit()
        return len(rows)


__all__ = ["RequeuePendingRawMessages"]
