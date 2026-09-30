"""Caso de uso: listar la cola de revision con paginacion por cursor (spec 005 SS7)."""

from uuid import UUID

from luka.modules.ledger.application.dto import Cursor, ReviewEntry, ReviewPage
from luka.modules.ledger.application.ports import ReviewQueueRepositoryPort, ReviewSourcePort


class ListReview:
    """Pagina los items abiertos del usuario, pidiendo `limit + 1` filas (spec 005 SS1)."""

    def __init__(
        self, *, review_queue: ReviewQueueRepositoryPort, review_source: ReviewSourcePort
    ) -> None:
        self._review_queue = review_queue
        self._review_source = review_source

    async def execute(self, user_id: UUID, cursor: Cursor | None, limit: int) -> ReviewPage:
        rows = await self._review_queue.list_open(user_id, cursor, limit + 1)
        has_more = len(rows) > limit
        items = rows[:limit]

        views = {}
        if items:
            ids = [item.raw_message_id for item in items]
            views = await self._review_source.load_views(user_id, ids)

        entries = tuple(
            ReviewEntry(item=item, source=views.get(item.raw_message_id)) for item in items
        )

        next_cursor: Cursor | None = None
        if has_more and items:
            last = items[-1]
            next_cursor = Cursor(sort_key=last.created_at, id=last.raw_message_id)

        return ReviewPage(items=entries, next_cursor=next_cursor)
