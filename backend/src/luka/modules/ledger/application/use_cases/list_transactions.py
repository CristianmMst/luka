"""Caso de uso: listar transacciones con paginacion por cursor (spec 005 SS1/SS6)."""

from uuid import UUID

from luka.modules.ledger.application.dto import Cursor, Filters, Page
from luka.modules.ledger.application.ports import (
    TransactionRepositoryPort,
    TransactionSourceRepositoryPort,
)


class ListTransactions:
    """Pagina transacciones propias segun `filters`, pidiendo `limit + 1` filas."""

    def __init__(
        self, *, transactions: TransactionRepositoryPort, sources: TransactionSourceRepositoryPort
    ) -> None:
        self._transactions = transactions
        self._sources = sources

    async def execute(
        self, user_id: UUID, filters: Filters, cursor: Cursor | None, limit: int
    ) -> Page:
        """Devuelve hasta `limit` transacciones y el cursor para continuar, si aplica."""
        rows = await self._transactions.list(user_id, filters, cursor, limit + 1)
        has_more = len(rows) > limit
        items = tuple(rows[:limit])

        next_cursor: Cursor | None = None
        if has_more and items:
            last = items[-1]
            sort_key = last.updated_at if filters.updated_since is not None else last.occurred_at
            next_cursor = Cursor(sort_key=sort_key, id=last.id)

        channels = await self._sources.channels_for([tx.id for tx in items]) if items else {}

        return Page(items=items, next_cursor=next_cursor, channels=channels)
