"""Repositorio SQLAlchemy de cuentas vinculadas (spec 004 SS2.4; controller ruling 1)."""

from uuid import UUID

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.ledger.domain.entities import LinkedAccount
from luka.modules.ledger.domain.enums import Bank
from luka.modules.ledger.infrastructure.mappers import (
    account_entity_to_row,
    account_row_to_entity,
)
from luka.modules.ledger.infrastructure.orm import LinkedAccountRow


class SqlAlchemyLinkedAccountRepository:
    """Implementacion SQLAlchemy de `LinkedAccountRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get(self, user_id: UUID, id: UUID) -> LinkedAccount | None:
        stmt = select(LinkedAccountRow).where(
            LinkedAccountRow.id == id, LinkedAccountRow.user_id == user_id
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return account_row_to_entity(row) if row is not None else None

    async def find_by_bank_last4(
        self, user_id: UUID, bank: Bank, last4: str
    ) -> LinkedAccount | None:
        stmt = select(LinkedAccountRow).where(
            LinkedAccountRow.user_id == user_id,
            LinkedAccountRow.bank == bank.value,
            LinkedAccountRow.last4 == last4,
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return account_row_to_entity(row) if row is not None else None

    async def list(self, user_id: UUID) -> list[LinkedAccount]:
        stmt = select(LinkedAccountRow).where(LinkedAccountRow.user_id == user_id)
        result = await self._session.execute(stmt)
        return [account_row_to_entity(row) for row in result.scalars()]

    async def exists(self, user_id: UUID, bank: Bank, last4: str | None) -> bool:
        stmt = (
            select(func.count())
            .select_from(LinkedAccountRow)
            .where(LinkedAccountRow.user_id == user_id, LinkedAccountRow.bank == bank.value)
        )
        stmt = stmt.where(
            LinkedAccountRow.last4.is_(None) if last4 is None else LinkedAccountRow.last4 == last4
        )
        count = (await self._session.execute(stmt)).scalar_one()
        return count > 0

    async def add(self, account: LinkedAccount) -> None:
        self._session.add(account_entity_to_row(account))
        await self._session.flush()

    async def update(self, account: LinkedAccount) -> None:
        row = await self._session.get(LinkedAccountRow, account.id)
        if row is None or row.user_id != account.user_id:
            return
        row.kind = account.kind.value
        row.last4 = account.last4
        row.alias = account.alias
        await self._session.flush()

    async def delete(self, user_id: UUID, id: UUID) -> None:
        stmt = delete(LinkedAccountRow).where(
            LinkedAccountRow.id == id, LinkedAccountRow.user_id == user_id
        )
        await self._session.execute(stmt)
