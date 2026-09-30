"""Caso de uso: desvincular una cuenta propia (spec 005 SS7)."""

from uuid import UUID

from luka.modules.ledger.application.ports import LinkedAccountRepositoryPort, UnitOfWorkPort
from luka.modules.ledger.domain.errors import AccountNotFound


class DeleteAccount:
    """Desvincula una cuenta propia. La FK de `transactions.account_id` queda en NULL."""

    def __init__(self, *, accounts: LinkedAccountRepositoryPort, uow: UnitOfWorkPort) -> None:
        self._accounts = accounts
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID) -> None:
        account = await self._accounts.get(user_id, id)
        if account is None:
            raise AccountNotFound

        await self._accounts.delete(user_id, id)
        await self._uow.commit()
