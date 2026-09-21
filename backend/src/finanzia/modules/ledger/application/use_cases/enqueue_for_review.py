"""Caso de uso: encolar un mensaje crudo para revision manual (spec 004 SS2.10, D1).

Se invoca desde el handler de `parsing.ParseFailed` (`infrastructure/consumers.py`,
F2.6). Idempotente (P2): `insert_if_absent` usa `ON CONFLICT DO NOTHING` sobre la PK
`raw_message_id`, asi que una reentrega del mismo evento no duplica el item.
"""

from finanzia.modules.ledger.application.dto import EnqueueForReviewCommand
from finanzia.modules.ledger.application.ports import (
    ClockPort,
    ReviewQueueRepositoryPort,
    UnitOfWorkPort,
)
from finanzia.modules.ledger.domain.review import ReviewItem


class EnqueueForReview:
    """Inserta (si no existia) un item abierto en la cola de revision."""

    def __init__(
        self,
        *,
        review_queue: ReviewQueueRepositoryPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._review_queue = review_queue
        self._clock = clock
        self._uow = uow

    async def execute(self, cmd: EnqueueForReviewCommand) -> None:
        """Inserta el item (no-op si `raw_message_id` ya estaba en la cola) y comitea."""
        item = ReviewItem(
            raw_message_id=cmd.raw_message_id,
            user_id=cmd.user_id,
            reason=cmd.reason,
            partial_extract=dict(cmd.partial_extract),
            created_at=self._clock.now(),
            resolved_at=None,
            resolution=None,
        )
        await self._review_queue.insert_if_absent(item)
        await self._uow.commit()
