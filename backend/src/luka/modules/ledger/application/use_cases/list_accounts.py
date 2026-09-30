"""Caso de uso: listar las cuentas vinculadas del usuario (spec 005 SS7)."""

from uuid import UUID

from luka.modules.ledger.application.ports import LinkedAccountRepositoryPort
from luka.modules.ledger.domain.entities import LinkedAccount


class ListAccounts:
    """Devuelve las cuentas vinculadas propias del usuario."""

    def __init__(self, *, accounts: LinkedAccountRepositoryPort) -> None:
        self._accounts = accounts

    async def execute(self, user_id: UUID) -> list[LinkedAccount]:
        return await self._accounts.list(user_id)
