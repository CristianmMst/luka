"""Dobles de prueba de ledger: repos en memoria y ports fake (sin infraestructura)."""

from __future__ import annotations

import uuid
from collections.abc import Sequence
from dataclasses import replace
from datetime import datetime
from decimal import Decimal
from uuid import UUID

from support.clock import FixedClock

from finanzia.modules.ledger.application.dto import Cursor, Filters, ReviewSourceView
from finanzia.modules.ledger.domain.entities import (
    Category,
    LinkedAccount,
    MerchantRule,
    Transaction,
    TransactionSource,
)
from finanzia.modules.ledger.domain.enums import Bank, Channel, Direction, FiscalTag, Kind
from finanzia.modules.ledger.domain.review import ReviewItem, ReviewResolution
from finanzia.modules.ledger.domain.system_categories import SYSTEM_CATEGORIES

__all__ = [
    "FakeReviewSource",
    "FixedClock",
    "InMemoryCategoryRepo",
    "InMemoryLinkedAccountRepo",
    "InMemoryMerchantRuleRepo",
    "InMemoryReviewQueueRepo",
    "InMemoryTransactionRepo",
    "InMemoryTransactionSourceRepo",
    "LedgerRepos",
    "NoopUoW",
    "RecordingPublisher",
    "SequenceIdGenerator",
    "build_ledger_repos",
    "seed_system_categories",
]


class InMemoryTransactionSourceRepo:
    """Doble en memoria de `TransactionSourceRepositoryPort`."""

    def __init__(self) -> None:
        self._by_tx: dict[UUID, list[TransactionSource]] = {}

    async def attach(self, source: TransactionSource) -> bool:
        existing = self._by_tx.setdefault(source.transaction_id, [])
        if source.raw_message_id is not None and any(
            s.raw_message_id == source.raw_message_id for s in existing
        ):
            return False
        existing.append(source)
        return True

    async def list_for(self, transaction_id: UUID) -> list[TransactionSource]:
        return list(self._by_tx.get(transaction_id, []))

    async def channels_for(self, ids: Sequence[UUID]) -> dict[UUID, list[Channel]]:
        id_set = set(ids)
        result: dict[UUID, list[Channel]] = {}
        for transaction_id, sources in self._by_tx.items():
            if transaction_id in id_set:
                unique = {s.channel for s in sources}
                if unique:
                    result[transaction_id] = list(unique)
        return result


def _matches_query(tx: Transaction, query: str | None) -> bool:
    if not query:
        return True
    needle = query.lower()
    haystacks = (tx.merchant, tx.description, tx.notes)
    return any(h is not None and needle in h.lower() for h in haystacks)


def _matches_filters(tx: Transaction, filters: Filters) -> bool:
    checks = (
        filters.from_ is None or tx.occurred_at >= filters.from_,
        filters.to is None or tx.occurred_at <= filters.to,
        filters.kind is None or tx.kind == filters.kind,
        filters.category_id is None or tx.category_id == filters.category_id,
        filters.bank is None or tx.bank == filters.bank,
        filters.account_id is None or tx.account_id == filters.account_id,
        filters.updated_since is None or tx.updated_at >= filters.updated_since,
        _matches_query(tx, filters.q),
    )
    return all(checks)


class InMemoryTransactionRepo:
    """Doble en memoria de `TransactionRepositoryPort`.

    `sources` es opcional y solo se usa para el filtro por `channel` en `list`
    (channel vive en `TransactionSource`, no en `Transaction`).
    """

    def __init__(self, *, sources: InMemoryTransactionSourceRepo | None = None) -> None:
        self._by_id: dict[UUID, Transaction] = {}
        self._dedupe_index: dict[tuple[UUID, str], UUID] = {}
        self._sources = sources

    async def insert_if_absent(self, tx: Transaction) -> UUID | None:
        key = (tx.user_id, tx.dedupe_key)
        if key in self._dedupe_index:
            return None
        self._by_id[tx.id] = tx
        self._dedupe_index[key] = tx.id
        return tx.id

    async def find_by_dedupe_keys(self, user_id: UUID, keys: Sequence[str]) -> list[Transaction]:
        key_set = set(keys)
        return [t for t in self._by_id.values() if t.user_id == user_id and t.dedupe_key in key_set]

    async def get(self, user_id: UUID, id: UUID) -> Transaction | None:
        tx = self._by_id.get(id)
        return tx if tx is not None and tx.user_id == user_id else None

    async def get_many(self, user_id: UUID, ids: Sequence[UUID]) -> list[Transaction]:
        id_set = set(ids)
        return [t for t in self._by_id.values() if t.user_id == user_id and t.id in id_set]

    async def list(
        self, user_id: UUID, filters: Filters, cursor: Cursor | None, limit: int
    ) -> list[Transaction]:
        rows = [t for t in self._by_id.values() if t.user_id == user_id]
        rows = [t for t in rows if _matches_filters(t, filters)]

        if self._sources is not None and filters.channel is not None:
            channel = filters.channel
            rows = [
                t
                for t in rows
                if any(s.channel == channel for s in await self._sources.list_for(t.id))
            ]

        use_updated = filters.updated_since is not None
        if use_updated:
            rows.sort(key=lambda t: (t.updated_at, t.id))
        else:
            rows.sort(key=lambda t: (t.occurred_at, t.id), reverse=True)

        if cursor is not None:
            if use_updated:
                rows = [t for t in rows if (t.updated_at, t.id) > (cursor.sort_key, cursor.id)]
            else:
                rows = [t for t in rows if (t.occurred_at, t.id) < (cursor.sort_key, cursor.id)]

        return rows[:limit]

    async def update(self, tx: Transaction) -> None:
        old = self._by_id.get(tx.id)
        if old is not None:
            self._dedupe_index.pop((old.user_id, old.dedupe_key), None)
        self._by_id[tx.id] = tx
        self._dedupe_index[(tx.user_id, tx.dedupe_key)] = tx.id

    async def touch(self, user_id: UUID, id: UUID, at: datetime) -> None:
        tx = self._by_id.get(id)
        if tx is not None and tx.user_id == user_id:
            self._by_id[id] = replace(tx, updated_at=at)

    async def delete(self, user_id: UUID, id: UUID) -> None:
        tx = self._by_id.get(id)
        if tx is not None and tx.user_id == user_id:
            del self._by_id[id]
            self._dedupe_index.pop((tx.user_id, tx.dedupe_key), None)

    async def find_transfer_candidates(
        self,
        user_id: UUID,
        direction: Direction,
        amount: Decimal,
        since: datetime,
        until: datetime,
    ) -> list[Transaction]:
        return [
            t
            for t in self._by_id.values()
            if t.user_id == user_id
            and t.direction == direction
            and t.amount == amount
            and since <= t.occurred_at <= until
        ]

    async def reassign_category(
        self,
        user_id: UUID,
        from_category_id: UUID,
        to_category_id: UUID,
        fiscal_tag: FiscalTag,
        now: datetime,
    ) -> int:
        count = 0
        for tx in list(self._by_id.values()):
            if tx.user_id == user_id and tx.category_id == from_category_id:
                # Invariante spec 004 SS2.5: una transferencia conserva
                # `fiscal_tag = 'transferencia'` sin importar la categoria destino.
                new_fiscal_tag = FiscalTag.TRANSFERENCIA if tx.kind == Kind.TRANSFER else fiscal_tag
                await self.update(
                    replace(
                        tx, category_id=to_category_id, fiscal_tag=new_fiscal_tag, updated_at=now
                    )
                )
                count += 1
        return count

    async def retag_category(
        self, user_id: UUID, category_id: UUID, fiscal_tag: FiscalTag, now: datetime
    ) -> int:
        count = 0
        for tx in list(self._by_id.values()):
            if tx.user_id == user_id and tx.category_id == category_id and tx.kind != Kind.TRANSFER:
                await self.update(replace(tx, fiscal_tag=fiscal_tag, updated_at=now))
                count += 1
        return count


class InMemoryCategoryRepo:
    """Doble en memoria de `CategoryRepositoryPort`."""

    def __init__(self) -> None:
        self._by_id: dict[UUID, Category] = {}

    async def get_visible(self, user_id: UUID, category_id: UUID) -> Category | None:
        category = self._by_id.get(category_id)
        if category is None:
            return None
        return category if category.is_system or category.user_id == user_id else None

    async def list_visible(self, user_id: UUID) -> list[Category]:
        return [c for c in self._by_id.values() if c.is_system or c.user_id == user_id]

    async def get_system_by_slug(self, slug: str) -> Category | None:
        for category in self._by_id.values():
            if category.is_system and category.slug == slug:
                return category
        return None

    async def exists_name(
        self, user_id: UUID, name: str, *, exclude_id: UUID | None = None
    ) -> bool:
        return any(
            (c.is_system or c.user_id == user_id)
            and c.name.lower() == name.lower()
            and c.id != exclude_id
            for c in self._by_id.values()
        )

    async def add(self, category: Category) -> None:
        self._by_id[category.id] = category

    async def update(self, category: Category) -> None:
        self._by_id[category.id] = category

    async def delete(self, user_id: UUID, id: UUID) -> None:
        category = self._by_id.get(id)
        if category is not None and category.user_id == user_id:
            del self._by_id[id]


async def seed_system_categories(repo: InMemoryCategoryRepo) -> None:
    """Carga las 24 categorias del sistema (`SYSTEM_CATEGORIES`) en `repo`."""
    for sc in SYSTEM_CATEGORIES:
        await repo.add(
            Category(
                id=sc.id,
                user_id=None,
                slug=sc.slug,
                name=sc.name,
                icon=None,
                color=None,
                fiscal_tag=sc.fiscal_tag,
            )
        )


class InMemoryLinkedAccountRepo:
    """Doble en memoria de `LinkedAccountRepositoryPort`."""

    def __init__(self) -> None:
        self._by_id: dict[UUID, LinkedAccount] = {}

    async def get(self, user_id: UUID, id: UUID) -> LinkedAccount | None:
        account = self._by_id.get(id)
        return account if account is not None and account.user_id == user_id else None

    async def find_by_bank_last4(
        self, user_id: UUID, bank: Bank, last4: str
    ) -> LinkedAccount | None:
        for account in self._by_id.values():
            if account.user_id == user_id and account.bank == bank and account.last4 == last4:
                return account
        return None

    async def list(self, user_id: UUID) -> list[LinkedAccount]:
        return [a for a in self._by_id.values() if a.user_id == user_id]

    async def exists(self, user_id: UUID, bank: Bank, last4: str | None) -> bool:
        return any(
            a.user_id == user_id and a.bank == bank and a.last4 == last4
            for a in self._by_id.values()
        )

    async def add(self, account: LinkedAccount) -> None:
        self._by_id[account.id] = account

    async def update(self, account: LinkedAccount) -> None:
        self._by_id[account.id] = account

    async def delete(self, user_id: UUID, id: UUID) -> None:
        account = self._by_id.get(id)
        if account is not None and account.user_id == user_id:
            del self._by_id[id]


class InMemoryMerchantRuleRepo:
    """Doble en memoria de `MerchantRuleRepositoryPort`: `upsert` por `(user_id, pattern)`."""

    def __init__(self) -> None:
        self._by_key: dict[tuple[UUID, str], MerchantRule] = {}

    async def upsert(self, rule: MerchantRule) -> None:
        self._by_key[(rule.user_id, rule.merchant_pattern)] = rule

    async def list_for_user(self, user_id: UUID) -> list[MerchantRule]:
        return [r for r in self._by_key.values() if r.user_id == user_id]

    async def delete_for_category(self, user_id: UUID, category_id: UUID) -> None:
        for key, rule in list(self._by_key.items()):
            if rule.user_id == user_id and rule.category_id == category_id:
                del self._by_key[key]


class RecordingPublisher:
    """Doble de `EventPublisherPort`: guarda cada evento publicado para inspeccion."""

    def __init__(self) -> None:
        self.events: list[object] = []

    async def publish(self, event: object) -> None:
        self.events.append(event)


class SequenceIdGenerator:
    """Doble de `IdGeneratorPort`: ids uuid5 deterministas y `random_hex` por contador."""

    def __init__(self) -> None:
        self._counter = 0

    def new_id(self) -> UUID:
        self._counter += 1
        return uuid.uuid5(uuid.NAMESPACE_URL, f"https://finanzia.app/test-ids/{self._counter}")

    def random_hex(self, n_bytes: int) -> str:
        self._counter += 1
        return f"{self._counter:0{n_bytes * 2}x}"


class NoopUoW:
    """Doble de `UnitOfWorkPort`: no persiste nada, solo cuenta los commits."""

    def __init__(self) -> None:
        self.commits = 0

    async def commit(self) -> None:
        self.commits += 1


class InMemoryReviewQueueRepo:
    """Doble en memoria de `ReviewQueueRepositoryPort`."""

    def __init__(self) -> None:
        self._by_id: dict[UUID, ReviewItem] = {}

    async def insert_if_absent(self, item: ReviewItem) -> bool:
        if item.raw_message_id in self._by_id:
            return False
        self._by_id[item.raw_message_id] = item
        return True

    async def get(self, user_id: UUID, raw_message_id: UUID) -> ReviewItem | None:
        item = self._by_id.get(raw_message_id)
        return item if item is not None and item.user_id == user_id else None

    async def list_open(self, user_id: UUID, cursor: Cursor | None, limit: int) -> list[ReviewItem]:
        rows = [i for i in self._by_id.values() if i.user_id == user_id and i.is_open]
        rows.sort(key=lambda i: (i.created_at, i.raw_message_id), reverse=True)
        if cursor is not None:
            rows = [
                i for i in rows if (i.created_at, i.raw_message_id) < (cursor.sort_key, cursor.id)
            ]
        return rows[:limit]

    async def resolve(
        self, user_id: UUID, raw_message_id: UUID, resolution: ReviewResolution, now: datetime
    ) -> bool:
        item = self._by_id.get(raw_message_id)
        if item is None or item.user_id != user_id or not item.is_open:
            return False
        self._by_id[raw_message_id] = replace(item, resolved_at=now, resolution=resolution)
        return True


class FakeReviewSource:
    """Doble de `ReviewSourcePort`: vistas precargadas a mano por el test."""

    def __init__(self) -> None:
        self.views: dict[UUID, ReviewSourceView] = {}
        self.marked: dict[UUID, tuple[str, datetime]] = {}

    async def load_views(self, user_id: UUID, ids: Sequence[UUID]) -> dict[UUID, ReviewSourceView]:
        del user_id
        return {i: self.views[i] for i in ids if i in self.views}

    async def mark_status(self, raw_message_id: UUID, status: str, now: datetime) -> bool:
        self.marked[raw_message_id] = (status, now)
        return True


class LedgerRepos:
    """Paquete de todos los dobles de ledger, ya conectados entre si."""

    def __init__(self) -> None:
        self.sources = InMemoryTransactionSourceRepo()
        self.transactions = InMemoryTransactionRepo(sources=self.sources)
        self.categories = InMemoryCategoryRepo()
        self.accounts = InMemoryLinkedAccountRepo()
        self.merchant_rules = InMemoryMerchantRuleRepo()
        self.review_queue = InMemoryReviewQueueRepo()
        self.events = RecordingPublisher()
        self.ids = SequenceIdGenerator()
        self.uow = NoopUoW()


async def build_ledger_repos() -> LedgerRepos:
    """`LedgerRepos` con las 24 categorias del sistema ya sembradas."""
    repos = LedgerRepos()
    await seed_system_categories(repos.categories)
    return repos
