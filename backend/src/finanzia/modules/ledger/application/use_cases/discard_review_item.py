"""Caso de uso: descartar un item de revision sin crear transaccion (spec 005 SS7)."""

from dataclasses import replace
from uuid import UUID

from finanzia.modules.ledger.application.ports import (
    ClockPort,
    ReviewQueueRepositoryPort,
    ReviewSourcePort,
    UnitOfWorkPort,
)
from finanzia.modules.ledger.domain.errors import ReviewAlreadyResolved, ReviewItemNotFound
from finanzia.modules.ledger.domain.review import ReviewItem, ReviewResolution


class DiscardReviewItem:
    """Resuelve el item como `discarded` y marca el `raw_message` en consecuencia."""

    def __init__(
        self,
        *,
        review_queue: ReviewQueueRepositoryPort,
        review_source: ReviewSourcePort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._review_queue = review_queue
        self._review_source = review_source
        self._clock = clock
        self._uow = uow

    async def execute(self, user_id: UUID, raw_message_id: UUID) -> ReviewItem:
        """`ReviewItemNotFound` (ajeno/inexistente) o `ReviewAlreadyResolved` (409)."""
        item = await self._review_queue.get(user_id, raw_message_id)
        if item is None:
            raise ReviewItemNotFound
        if not item.is_open:
            raise ReviewAlreadyResolved

        now = self._clock.now()
        # Mismo guard optimista que `ConvertReviewItem`: `resolve` devuelve `False`
        # si otra transaccion resolvio el item entre el `get` y este UPDATE.
        if not await self._review_queue.resolve(
            user_id, raw_message_id, ReviewResolution.DISCARDED, now
        ):
            raise ReviewAlreadyResolved
        await self._review_source.mark_status(raw_message_id, "discarded", now)
        await self._uow.commit()

        return replace(item, resolved_at=now, resolution=ReviewResolution.DISCARDED)
