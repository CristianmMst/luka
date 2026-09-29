r"""Repositorio SQLAlchemy de transacciones (spec 004 SS2.5, SS3, SS4; controller ruling 1).

Toda consulta filtra por `user_id` (009 SS4). `list` implementa paginacion keyset:
orden por defecto `(occurred_at DESC, id DESC)`; con `filters.updated_since`, orden
`(updated_at ASC, id ASC)`. `q` busca con `ILIKE` escapando `%`, `_` y `\` del texto
del usuario para que esos caracteres nunca actuen como comodines (spec 005 SS6).

`from __future__ import annotations` evita que pyright confunda el metodo `list`
(exigido por `TransactionRepositoryPort`) con el tipo builtin `list[...]` usado en
las anotaciones de esta clase (ambos comparten nombre en el mismo scope).
"""

from __future__ import annotations

from collections.abc import Collection, Sequence
from datetime import datetime
from decimal import Decimal
from typing import cast
from uuid import UUID

from sqlalchemy import CursorResult, Select, case, delete, exists, or_, select, tuple_, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from finanzia.modules.ledger.application.dto import Cursor, Filters
from finanzia.modules.ledger.domain.entities import Transaction
from finanzia.modules.ledger.domain.enums import Direction, FiscalTag
from finanzia.modules.ledger.infrastructure.mappers import (
    transaction_entity_to_values,
    transaction_row_to_entity,
)
from finanzia.modules.ledger.infrastructure.orm import TransactionRow, TransactionSourceRow

_LIKE_ESCAPE = "\\"


def _escape_like(raw: str) -> str:
    """Escapa `\\`, `%` y `_` para que `q` nunca se interprete como patron `ILIKE`."""
    return raw.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


class SqlAlchemyTransactionRepository:
    """Implementacion SQLAlchemy de `TransactionRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def insert_if_absent(self, tx: Transaction) -> UUID | None:
        stmt = (
            pg_insert(TransactionRow)
            .values(**transaction_entity_to_values(tx))
            .on_conflict_do_nothing(index_elements=["user_id", "dedupe_key"])
            .returning(TransactionRow.id)
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def find_by_dedupe_keys(self, user_id: UUID, keys: Sequence[str]) -> list[Transaction]:
        if not keys:
            return []
        stmt = select(TransactionRow).where(
            TransactionRow.user_id == user_id, TransactionRow.dedupe_key.in_(keys)
        )
        result = await self._session.execute(stmt)
        return [transaction_row_to_entity(row) for row in result.scalars()]

    async def get(self, user_id: UUID, id: UUID) -> Transaction | None:
        stmt = select(TransactionRow).where(
            TransactionRow.id == id, TransactionRow.user_id == user_id
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return transaction_row_to_entity(row) if row is not None else None

    async def get_many(self, user_id: UUID, ids: Sequence[UUID]) -> list[Transaction]:
        if not ids:
            return []
        stmt = select(TransactionRow).where(
            TransactionRow.user_id == user_id, TransactionRow.id.in_(ids)
        )
        result = await self._session.execute(stmt)
        return [transaction_row_to_entity(row) for row in result.scalars()]

    async def list(
        self, user_id: UUID, filters: Filters, cursor: Cursor | None, limit: int
    ) -> list[Transaction]:
        stmt: Select[tuple[TransactionRow]] = select(TransactionRow).where(
            TransactionRow.user_id == user_id
        )
        stmt = self._apply_filters(stmt, filters)

        if filters.updated_since is not None:
            stmt = stmt.where(TransactionRow.updated_at >= filters.updated_since)
            if cursor is not None:
                stmt = stmt.where(
                    tuple_(TransactionRow.updated_at, TransactionRow.id)
                    > (cursor.sort_key, cursor.id)
                )
            stmt = stmt.order_by(TransactionRow.updated_at.asc(), TransactionRow.id.asc())
        else:
            if cursor is not None:
                stmt = stmt.where(
                    tuple_(TransactionRow.occurred_at, TransactionRow.id)
                    < (cursor.sort_key, cursor.id)
                )
            stmt = stmt.order_by(TransactionRow.occurred_at.desc(), TransactionRow.id.desc())

        stmt = stmt.limit(limit)
        result = await self._session.execute(stmt)
        return [transaction_row_to_entity(row) for row in result.scalars()]

    def _apply_filters(
        self, stmt: Select[tuple[TransactionRow]], filters: Filters
    ) -> Select[tuple[TransactionRow]]:
        if filters.from_ is not None:
            stmt = stmt.where(TransactionRow.occurred_at >= filters.from_)
        if filters.to is not None:
            stmt = stmt.where(TransactionRow.occurred_at < filters.to)
        if filters.kind is not None:
            stmt = stmt.where(TransactionRow.kind == filters.kind.value)
        if filters.category_id is not None:
            stmt = stmt.where(TransactionRow.category_id == filters.category_id)
        if filters.bank is not None:
            stmt = stmt.where(TransactionRow.bank == filters.bank.value)
        if filters.account_id is not None:
            stmt = stmt.where(TransactionRow.account_id == filters.account_id)
        if filters.channel is not None:
            stmt = stmt.where(
                exists().where(
                    TransactionSourceRow.transaction_id == TransactionRow.id,
                    TransactionSourceRow.channel == filters.channel.value,
                )
            )
        if filters.q:
            pattern = f"%{_escape_like(filters.q)}%"
            stmt = stmt.where(
                or_(
                    TransactionRow.merchant.ilike(pattern, escape=_LIKE_ESCAPE),
                    TransactionRow.description.ilike(pattern, escape=_LIKE_ESCAPE),
                    TransactionRow.notes.ilike(pattern, escape=_LIKE_ESCAPE),
                )
            )
        return stmt

    async def update(self, tx: Transaction) -> None:
        values = transaction_entity_to_values(tx)
        values.pop("id")
        values.pop("user_id")
        stmt = (
            update(TransactionRow)
            .where(TransactionRow.id == tx.id, TransactionRow.user_id == tx.user_id)
            .values(**values)
        )
        await self._session.execute(stmt)

    async def find_non_transfers_by_parsed_by(
        self, parsed_by: Collection[str], user_id: UUID | None
    ) -> list[Transaction]:
        if not parsed_by:
            return []
        stmt = select(TransactionRow).where(
            TransactionRow.parsed_by.in_(list(parsed_by)),
            TransactionRow.kind != "transfer",
        )
        if user_id is not None:
            stmt = stmt.where(TransactionRow.user_id == user_id)
        result = await self._session.execute(stmt.order_by(TransactionRow.created_at))
        return [transaction_row_to_entity(row) for row in result.scalars()]

    async def touch(self, user_id: UUID, id: UUID, at: datetime) -> None:
        stmt = (
            update(TransactionRow)
            .where(TransactionRow.id == id, TransactionRow.user_id == user_id)
            .values(updated_at=at)
        )
        await self._session.execute(stmt)

    async def delete(self, user_id: UUID, id: UUID) -> None:
        stmt = delete(TransactionRow).where(
            TransactionRow.id == id, TransactionRow.user_id == user_id
        )
        await self._session.execute(stmt)

    async def find_transfer_candidates(
        self,
        user_id: UUID,
        direction: Direction,
        amount: Decimal,
        since: datetime,
        until: datetime,
    ) -> list[Transaction]:
        stmt = select(TransactionRow).where(
            TransactionRow.user_id == user_id,
            TransactionRow.direction == direction.value,
            TransactionRow.amount == amount,
            TransactionRow.occurred_at.between(since, until),
            TransactionRow.account_id.isnot(None),
            TransactionRow.transfer_pair_id.is_(None),
            TransactionRow.kind != "transfer",
        )
        result = await self._session.execute(stmt)
        return [transaction_row_to_entity(row) for row in result.scalars()]

    async def reassign_category(
        self,
        user_id: UUID,
        from_category_id: UUID,
        to_category_id: UUID,
        fiscal_tag: FiscalTag,
        now: datetime,
    ) -> int:
        # Invariante spec 004 SS2.5: `fiscal_tag = 'transferencia'` siempre que
        # `kind = 'transfer'`, sin importar la categoria destino de la reasignacion.
        new_fiscal_tag = case(
            (TransactionRow.kind == "transfer", FiscalTag.TRANSFERENCIA.value),
            else_=fiscal_tag.value,
        )
        stmt = (
            update(TransactionRow)
            .where(
                TransactionRow.user_id == user_id,
                TransactionRow.category_id == from_category_id,
            )
            .values(category_id=to_category_id, fiscal_tag=new_fiscal_tag, updated_at=now)
        )
        result = cast("CursorResult[tuple[()]]", await self._session.execute(stmt))
        return result.rowcount

    async def retag_category(
        self, user_id: UUID, category_id: UUID, fiscal_tag: FiscalTag, now: datetime
    ) -> int:
        stmt = (
            update(TransactionRow)
            .where(
                TransactionRow.user_id == user_id,
                TransactionRow.category_id == category_id,
                TransactionRow.kind != "transfer",
            )
            .values(fiscal_tag=fiscal_tag.value, updated_at=now)
        )
        result = cast("CursorResult[tuple[()]]", await self._session.execute(stmt))
        return result.rowcount
