"""Repositorio SQLAlchemy de reglas de comercio (spec 004 SS2.9; controller ruling 1)."""

from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.ledger.domain.entities import MerchantRule
from luka.modules.ledger.infrastructure.mappers import merchant_rule_row_to_entity
from luka.modules.ledger.infrastructure.orm import MerchantRuleRow


class SqlAlchemyMerchantRuleRepository:
    """Implementacion SQLAlchemy de `MerchantRuleRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def upsert(self, rule: MerchantRule) -> None:
        stmt = (
            pg_insert(MerchantRuleRow)
            .values(
                id=rule.id,
                user_id=rule.user_id,
                merchant_pattern=rule.merchant_pattern,
                category_id=rule.category_id,
            )
            .on_conflict_do_update(
                index_elements=["user_id", "merchant_pattern"],
                set_={"category_id": rule.category_id},
            )
        )
        await self._session.execute(stmt)

    async def list_for_user(self, user_id: UUID) -> list[MerchantRule]:
        stmt = select(MerchantRuleRow).where(MerchantRuleRow.user_id == user_id)
        result = await self._session.execute(stmt)
        return [merchant_rule_row_to_entity(row) for row in result.scalars()]

    async def delete_for_category(self, user_id: UUID, category_id: UUID) -> None:
        stmt = delete(MerchantRuleRow).where(
            MerchantRuleRow.user_id == user_id, MerchantRuleRow.category_id == category_id
        )
        await self._session.execute(stmt)
