"""Caso de uso: reprocesar mensajes crudos `failed` (spec 005 §7, spec 006 §4.4).

Cuando una plantilla nueva (o un arreglo del parser) llega despues de que un
mensaje ya cayo en revision, este caso de uso lo devuelve al pipeline: pone la
fila en `pending` y republica `RawMessageReceived` por el mismo camino que el
cron de reencolado (`received_event`). Si ahora parsea, ledger registra la
transaccion y cierra el item de revision abierto como `reparsed`; si vuelve a
fallar, el `event_id` determinista de `ParseFailed` y el `ON CONFLICT DO NOTHING`
de la cola dejan el mismo item abierto, sin duplicarlo.

Solo toma filas con `body` presente: un cuerpo purgado (90 dias, spec 004 §6) no
tiene nada que parsear. El UPDATE `failed -> pending` es condicional, asi que una
fila que el usuario convirtio o descarto entre la lectura y el UPDATE no se toca.

Orden commit -> publish (al reves que el reencolado): la fila debe estar `pending`
cuando parsing lea el evento, o `ParseRawMessage` lo descartaria con
`Skipped(not_pending)`. Si el publish falla tras el commit, la fila queda
`pending` con `requeue_attempts=0` y el cron de reencolado la republica.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from luka.modules.ingestion.application.dto import ReparseSummary
from luka.modules.ingestion.application.use_cases.requeue_pending import received_event

if TYPE_CHECKING:
    from datetime import datetime
    from uuid import UUID

    from luka.modules.ingestion.application.ports import (
        ClockPort,
        EventPublisherPort,
        IdGeneratorPort,
        RawMessageRepositoryPort,
        UnitOfWorkPort,
    )

_LIMIT_DEFAULT = 500


class ReparseFailedRawMessages:
    """Devuelve a `pending` las filas `failed` con cuerpo y republica su evento."""

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
        user_id: UUID | None = None,
        since: datetime | None = None,
        limit: int = _LIMIT_DEFAULT,
    ) -> ReparseSummary:
        """Reencola hasta `limit` filas `failed` (de `user_id` y recibidas desde
        `since`, si se dan). Comitea una vez y luego publica.
        """
        now = self._clock.now()
        rows = await self._repo.list_failed_for_reparse(user_id=user_id, since=since, limit=limit)
        reset = [row for row in rows if await self._repo.reset_failed_to_pending(row.id, now)]
        await self._uow.commit()
        for row in reset:
            await self._events.publish(received_event(row, self._ids.new_id(), now))
        return ReparseSummary(reparsed=len(reset))


__all__ = ["ReparseFailedRawMessages"]
