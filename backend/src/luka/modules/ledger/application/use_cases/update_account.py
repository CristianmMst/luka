"""Caso de uso: editar una cuenta vinculada propia (spec 005 SS7)."""

from dataclasses import replace
from uuid import UUID

from luka.modules.ledger.application.dto import UNSET, AccountPatch
from luka.modules.ledger.application.ports import LinkedAccountRepositoryPort, UnitOfWorkPort
from luka.modules.ledger.domain.entities import LinkedAccount
from luka.modules.ledger.domain.errors import AccountNotFound, DuplicateAccount


class UpdateAccount:
    """Edita `kind`/`last4`/`alias` de una cuenta propia (el banco no es editable)."""

    def __init__(self, *, accounts: LinkedAccountRepositoryPort, uow: UnitOfWorkPort) -> None:
        self._accounts = accounts
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID, patch: AccountPatch) -> LinkedAccount:
        account = await self._accounts.get(user_id, id)
        if account is None:
            raise AccountNotFound

        new_last4 = patch.last4
        if new_last4 is not UNSET and new_last4 != account.last4:
            if await self._accounts.exists(user_id, account.bank, new_last4):
                raise DuplicateAccount
            account = replace(account, last4=new_last4)
        if patch.kind is not UNSET:
            account = replace(account, kind=patch.kind)
        if patch.alias is not UNSET:
            account = replace(account, alias=patch.alias)

        await self._accounts.update(account)
        await self._uow.commit()
        return account
