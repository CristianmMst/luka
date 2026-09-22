"""Caso de uso: reencolado de mensajes `pending` huerfanos (riesgo 4, cron cada 15 min).

Mitiga la falta de outbox (spec 003 §2.3, D9): si el commit de `insert_if_absent`
tuvo exito pero la publicacion de `RawMessageReceived` fallo (o se perdio en el
worker antes de procesarla), la fila queda `pending` para siempre sin este cron.
Republica el evento para toda fila `pending` cuyo `updated_at` sea mas viejo que
`older_than` (10 min por defecto le da margen al camino feliz: ingesta -> publish
-> consumo por `parsing` antes de considerarla huerfana) y le actualiza
`updated_at` (`mark_requeued`) para no volver a republicarla en la misma ventana.

El reencolado esta acotado (`max_attempts`): una fila que ya se republico
`max_attempts` veces pasa a `failed` en vez de volver al stream, cerrando el
ciclo infinito cron -> 5 entregas -> DLQ -> sigue `pending` -> cron ...
"""

from __future__ import annotations

from datetime import timedelta
from typing import TYPE_CHECKING

from finanzia.modules.ingestion.application.dto import RequeueSummary
from finanzia.modules.ingestion.domain.enums import RawMessageStatus
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
#: Republicaciones permitidas por fila antes de darla por perdida (riesgo 4 / D9).
#: Sin esta cota, un mensaje que falla siempre queda en un ciclo infinito: el
#: consumer lo reintenta `max_deliveries` veces, lo manda a la DLQ y lo ACKea,
#: pero la fila sigue `pending` y este cron la republica cada ~15 min para
#: siempre. Con la cota, a la republicacion numero 6 la fila pasa a `failed`
#: (5 x 5 entregas = 25 intentos reales de parseo antes de rendirse).
_MAX_ATTEMPTS_DEFAULT = 5


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
        max_attempts: int = _MAX_ATTEMPTS_DEFAULT,
    ) -> RequeueSummary:
        """Republica las filas huerfanas y agota las que ya se republicaron de mas.

        Devuelve cuantas se republicaron y cuantas pasaron a `failed` por superar
        `max_attempts` (esas ultimas ya no las vuelve a tomar el cron: dejan de
        estar `pending`). Comitea una sola vez al final.
        """
        now = self._clock.now()
        before = now - older_than
        rows = await self._repo.list_pending_older_than(before, limit)

        requeued = 0
        exhausted = 0
        for row in rows:
            if row.requeue_attempts >= max_attempts:
                await self._repo.set_status(row.id, RawMessageStatus.FAILED, now)
                exhausted += 1
                continue
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
            await self._repo.mark_requeued(row.id, now)
            requeued += 1

        await self._uow.commit()
        return RequeueSummary(requeued=requeued, exhausted=exhausted)


__all__ = ["RequeuePendingRawMessages", "RequeueSummary"]
