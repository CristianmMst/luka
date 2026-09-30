"""Caso de uso: vincular una cuenta o tarjeta (spec 005 SS7)."""

from uuid import UUID

from luka.modules.ledger.application.dto import AccountInput
from luka.modules.ledger.application.ports import (
    IdGeneratorPort,
    LinkedAccountRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.ledger.domain.entities import LinkedAccount
from luka.modules.ledger.domain.errors import DuplicateAccount


class CreateAccount:
    """Vincula una cuenta propia; `(bank, last4)` debe ser unico para el usuario (409)."""

    def __init__(
        self,
        *,
        accounts: LinkedAccountRepositoryPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._accounts = accounts
        self._ids = ids
        self._uow = uow

    async def execute(self, user_id: UUID, input: AccountInput) -> LinkedAccount:
        if await self._accounts.exists(user_id, input.bank, input.last4):
            raise DuplicateAccount

        account = LinkedAccount(
            id=self._ids.new_id(),
            user_id=user_id,
            bank=input.bank,
            kind=input.kind,
            last4=input.last4,
            alias=input.alias,
        )
        await self._accounts.add(account)
        await self._uow.commit()
        return account
