"""Caso de uso: obtener el detalle de una transaccion propia (spec 005 SS6)."""

from uuid import UUID

from finanzia.modules.ledger.application.dto import TransactionDetail
from finanzia.modules.ledger.application.ports import (
    TransactionRepositoryPort,
    TransactionSourceRepositoryPort,
)
from finanzia.modules.ledger.domain.errors import TransactionNotFound


class GetTransaction:
    """Devuelve una transaccion propia junto con sus fuentes y su contraparte de pareo."""

    def __init__(
        self,
        *,
        transactions: TransactionRepositoryPort,
        sources: TransactionSourceRepositoryPort,
    ) -> None:
        self._transactions = transactions
        self._sources = sources

    async def execute(self, user_id: UUID, id: UUID) -> TransactionDetail:
        """Lanza `TransactionNotFound` si `id` no existe o no es del usuario."""
        tx = await self._transactions.get(user_id, id)
        if tx is None:
            raise TransactionNotFound

        sources = await self._sources.list_for(tx.id)
        pair = None
        if tx.transfer_pair_id is not None:
            pair = await self._transactions.get(user_id, tx.transfer_pair_id)

        return TransactionDetail(transaction=tx, sources=tuple(sources), pair=pair)
