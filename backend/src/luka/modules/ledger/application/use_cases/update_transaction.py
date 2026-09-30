"""Caso de uso: editar una transaccion propia (spec 005 SS6, AC-6.3/AC-7.2)."""

from dataclasses import replace
from datetime import datetime
from uuid import UUID

from luka.modules.ledger.application.dto import UNSET, TransactionPatch
from luka.modules.ledger.application.ports import (
    CategoryRepositoryPort,
    ClockPort,
    IdGeneratorPort,
    MerchantRuleRepositoryPort,
    TransactionRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.ledger.domain.classification import (
    derive_kind,
    mark_as_transfer,
    resolve_fiscal_tag,
    unmark_transfer,
)
from luka.modules.ledger.domain.entities import MerchantRule, Transaction
from luka.modules.ledger.domain.enums import FiscalTag, Kind
from luka.modules.ledger.domain.errors import (
    CategoryNotFound,
    InvalidKindChange,
    TransactionNotFound,
)
from luka.modules.ledger.domain.merchant import normalize_merchant
from luka.modules.ledger.domain.transfers import unpair


class UpdateTransaction:
    """Aplica un PATCH parcial: notas, comercio, categoria (con aprendizaje) y kind."""

    def __init__(  # noqa: PLR0913 - un puerto por dependencia externa
        self,
        *,
        transactions: TransactionRepositoryPort,
        categories: CategoryRepositoryPort,
        merchant_rules: MerchantRuleRepositoryPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._transactions = transactions
        self._categories = categories
        self._merchant_rules = merchant_rules
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID, patch: TransactionPatch) -> Transaction:
        """Lanza `TransactionNotFound`/`CategoryNotFound`/`InvalidKindChange` segun aplique."""
        tx = await self._transactions.get(user_id, id)
        if tx is None:
            raise TransactionNotFound

        now = self._clock.now()

        if patch.notes is not UNSET:
            tx = replace(tx, notes=patch.notes)
        if patch.merchant is not UNSET:
            tx = replace(tx, merchant=patch.merchant)

        new_category_id = patch.category_id
        if new_category_id is not UNSET:
            tx = await self._apply_category_change(
                user_id, tx, new_category_id, learn_merchant_rule=patch.learn_merchant_rule
            )

        new_kind = patch.kind
        if new_kind is not UNSET:
            tx = await self._apply_kind_change(user_id, tx, new_kind, now)

        tx = replace(tx, updated_at=now)
        await self._transactions.update(tx)
        await self._uow.commit()
        return tx

    async def _apply_category_change(
        self, user_id: UUID, tx: Transaction, category_id: UUID, *, learn_merchant_rule: bool
    ) -> Transaction:
        category = await self._categories.get_visible(user_id, category_id)
        if category is None:
            raise CategoryNotFound
        category_changed = category.id != tx.category_id
        tx = replace(
            tx,
            category_id=category.id,
            fiscal_tag=resolve_fiscal_tag(tx.kind, category.fiscal_tag),
        )
        if learn_merchant_rule and category_changed:
            normalized = normalize_merchant(tx.merchant)
            if normalized:
                await self._merchant_rules.upsert(
                    MerchantRule(
                        id=self._ids.new_id(),
                        user_id=user_id,
                        merchant_pattern=normalized,
                        category_id=category.id,
                    )
                )
        return tx

    async def _apply_kind_change(
        self, user_id: UUID, tx: Transaction, new_kind: Kind, now: datetime
    ) -> Transaction:
        if new_kind in (Kind.EXPENSE, Kind.INCOME) and new_kind != derive_kind(tx.direction):
            raise InvalidKindChange("kind incompatible con la direccion de la transaccion")

        if new_kind == Kind.TRANSFER and tx.kind != Kind.TRANSFER:
            return mark_as_transfer(tx, now=now)

        if new_kind != Kind.TRANSFER and tx.kind == Kind.TRANSFER:
            if tx.transfer_pair_id is not None:
                other = await self._transactions.get(user_id, tx.transfer_pair_id)
                if other is None:
                    raise TransactionNotFound
                tag_tx = await self._category_fiscal_tag(user_id, tx.category_id)
                tag_other = await self._category_fiscal_tag(user_id, other.category_id)
                updated_tx, updated_other = unpair(
                    tx, other, category_tags=(tag_tx, tag_other), now=now
                )
                await self._transactions.update(updated_other)
                return updated_tx
            tag = await self._category_fiscal_tag(user_id, tx.category_id)
            return unmark_transfer(tx, category_fiscal_tag=tag, now=now)

        return tx

    async def _category_fiscal_tag(self, user_id: UUID, category_id: UUID) -> FiscalTag:
        category = await self._categories.get_visible(user_id, category_id)
        if category is None:
            raise CategoryNotFound
        return category.fiscal_tag
