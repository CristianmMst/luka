"""Tests de integracion de los repositorios SQLAlchemy de ledger (F1.7, ruling 1).

Ejercita directamente `SqlAlchemyTransactionRepository`/`SqlAlchemyTransactionSourceRepository`
contra Postgres real: dedupe (`insert_if_absent`), idempotencia de fuentes (`attach`),
aislamiento por usuario (`list`), escape de `%`/`_` en `q` y la ventana del matcher de
transferencias (`find_transfer_candidates`).
"""

from collections.abc import Awaitable, Callable
from dataclasses import replace
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.raw_messages import insert_raw_message

from luka.modules.ledger.application.dto import Filters
from luka.modules.ledger.domain.entities import LinkedAccount, Transaction, TransactionSource
from luka.modules.ledger.domain.enums import (
    AccountKind,
    Bank,
    Channel,
    Direction,
    FiscalTag,
    Kind,
)
from luka.modules.ledger.domain.system_categories import (
    SIN_CATEGORIA_ID,
    system_category_id,
)
from luka.modules.ledger.infrastructure.repositories.accounts import (
    SqlAlchemyLinkedAccountRepository,
)
from luka.modules.ledger.infrastructure.repositories.sources import (
    SqlAlchemyTransactionSourceRepository,
)
from luka.modules.ledger.infrastructure.repositories.transactions import (
    SqlAlchemyTransactionRepository,
)

pytestmark = pytest.mark.integration


def _make_tx(  # noqa: PLR0913 - fabrica de test, un parametro por atributo relevante
    *,
    user_id: UUID,
    dedupe_key: str,
    merchant: str | None = None,
    occurred_at: datetime | None = None,
    amount: str = "100.00",
    direction: Direction = Direction.DEBIT,
    account_id: UUID | None = None,
) -> Transaction:
    now = occurred_at or datetime.now(UTC)
    return Transaction(
        id=uuid4(),
        user_id=user_id,
        amount=Decimal(amount),
        currency="COP",
        direction=direction,
        kind=Kind.EXPENSE if direction == Direction.DEBIT else Kind.INCOME,
        occurred_at=now,
        merchant=merchant,
        description=None,
        bank=None,
        account_id=account_id,
        category_id=SIN_CATEGORIA_ID,
        fiscal_tag=FiscalTag.NO_DEDUCIBLE,
        transfer_pair_id=None,
        transfer_auto=False,
        transfer_exclusions=frozenset(),
        dedupe_key=dedupe_key,
        parsed_by="manual",
        confidence=None,
        notes=None,
        created_at=now,
        updated_at=now,
    )


async def test_insert_if_absent_devuelve_none_en_segundo_insert(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    tx = _make_tx(user_id=user.id, dedupe_key="dedupe-repo-1")

    async with session_factory() as session:
        repo = SqlAlchemyTransactionRepository(session)
        first_id = await repo.insert_if_absent(tx)
        await session.commit()
    assert first_id == tx.id

    async with session_factory() as session:
        repo = SqlAlchemyTransactionRepository(session)
        second = _make_tx(user_id=user.id, dedupe_key="dedupe-repo-1")
        second_id = await repo.insert_if_absent(second)
        await session.commit()
    assert second_id is None


async def test_attach_idempotente_para_mismo_raw_message_id(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    tx = _make_tx(user_id=user.id, dedupe_key="dedupe-repo-attach")
    async with session_factory() as session:
        await SqlAlchemyTransactionRepository(session).insert_if_absent(tx)
        await session.commit()

    raw_message_id = await insert_raw_message(session_factory, user_id=user.id)
    source = TransactionSource(
        id=uuid4(),
        transaction_id=tx.id,
        raw_message_id=raw_message_id,
        channel=Channel.EMAIL,
        received_at=datetime.now(UTC),
    )

    async with session_factory() as session:
        first = await SqlAlchemyTransactionSourceRepository(session).attach(source)
        await session.commit()
    assert first is True

    async with session_factory() as session:
        duplicate = TransactionSource(
            id=uuid4(),
            transaction_id=tx.id,
            raw_message_id=raw_message_id,
            channel=Channel.EMAIL,
            received_at=datetime.now(UTC),
        )
        second = await SqlAlchemyTransactionSourceRepository(session).attach(duplicate)
        await session.commit()
    assert second is False


async def test_attach_siempre_true_cuando_raw_message_id_es_none(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    tx = _make_tx(user_id=user.id, dedupe_key="dedupe-repo-attach-null")
    async with session_factory() as session:
        await SqlAlchemyTransactionRepository(session).insert_if_absent(tx)
        await session.commit()

    async with session_factory() as session:
        repo = SqlAlchemyTransactionSourceRepository(session)
        for _ in range(2):
            result = await repo.attach(
                TransactionSource(
                    id=uuid4(),
                    transaction_id=tx.id,
                    raw_message_id=None,
                    channel=Channel.MANUAL,
                    received_at=datetime.now(UTC),
                )
            )
            assert result is True
        await session.commit()

    async with session_factory() as session:
        sources = await SqlAlchemyTransactionSourceRepository(session).list_for(tx.id)
    assert len(sources) == 2


async def test_touch_solo_actualiza_updated_at_y_no_pisa_un_patch_concurrente(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """El camino de dedupe lee `target` sin lock; si un PATCH de categoria entra entre
    la lectura y el touch, el touch no debe revertirlo (reescribe solo `updated_at`).
    """
    user = await user_factory(sub="sub-repo-touch", email="repo-touch@example.com")
    stale = _make_tx(user_id=user.id, dedupe_key="dedupe-touch-1")
    async with session_factory() as session:
        await SqlAlchemyTransactionRepository(session).insert_if_absent(stale)
        await session.commit()

    mercado = system_category_id("mercado")
    async with session_factory() as session:
        await SqlAlchemyTransactionRepository(session).update(
            replace(stale, category_id=mercado, notes="corregida por el usuario")
        )
        await session.commit()

    touched_at = stale.updated_at + timedelta(minutes=5)
    async with session_factory() as session:
        await SqlAlchemyTransactionRepository(session).touch(stale.user_id, stale.id, touched_at)
        await session.commit()

    async with session_factory() as session:
        stored = await SqlAlchemyTransactionRepository(session).get(user.id, stale.id)
    assert stored is not None
    assert stored.updated_at == touched_at
    assert stored.category_id == mercado
    assert stored.notes == "corregida por el usuario"


async def test_touch_no_toca_transacciones_de_otro_usuario(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    owner = await user_factory(sub="sub-repo-touch-a", email="repo-touch-a@example.com")
    other = await user_factory(sub="sub-repo-touch-b", email="repo-touch-b@example.com")
    tx = _make_tx(user_id=owner.id, dedupe_key="dedupe-touch-2")
    async with session_factory() as session:
        await SqlAlchemyTransactionRepository(session).insert_if_absent(tx)
        await session.commit()

    async with session_factory() as session:
        await SqlAlchemyTransactionRepository(session).touch(
            other.id, tx.id, tx.updated_at + timedelta(minutes=5)
        )
        await session.commit()

    async with session_factory() as session:
        stored = await SqlAlchemyTransactionRepository(session).get(owner.id, tx.id)
    assert stored is not None
    assert stored.updated_at == tx.updated_at


async def test_list_respeta_user_id(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user_a = await user_factory(sub="sub-repo-list-a", email="repo-list-a@example.com")
    user_b = await user_factory(sub="sub-repo-list-b", email="repo-list-b@example.com")

    async with session_factory() as session:
        repo = SqlAlchemyTransactionRepository(session)
        await repo.insert_if_absent(_make_tx(user_id=user_a.id, dedupe_key="dedupe-list-a"))
        await repo.insert_if_absent(_make_tx(user_id=user_b.id, dedupe_key="dedupe-list-b"))
        await session.commit()

    async with session_factory() as session:
        repo = SqlAlchemyTransactionRepository(session)
        rows_a = await repo.list(user_a.id, Filters(), None, 50)

    assert {row.user_id for row in rows_a} == {user_a.id}
    assert len(rows_a) == 1


async def test_q_escapa_wildcards_de_like(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    async with session_factory() as session:
        repo = SqlAlchemyTransactionRepository(session)
        await repo.insert_if_absent(
            _make_tx(user_id=user.id, dedupe_key="dedupe-q-percent", merchant="100%")
        )
        await repo.insert_if_absent(
            _make_tx(user_id=user.id, dedupe_key="dedupe-q-rappi", merchant="Rappi")
        )
        await repo.insert_if_absent(
            _make_tx(user_id=user.id, dedupe_key="dedupe-q-underscore", merchant="under_score")
        )
        await session.commit()

    async with session_factory() as session:
        repo = SqlAlchemyTransactionRepository(session)
        exact_match = await repo.list(user.id, Filters(q="100%"), None, 50)
        percent_only = await repo.list(user.id, Filters(q="%"), None, 50)
        underscore_only = await repo.list(user.id, Filters(q="_"), None, 50)

    assert {row.merchant for row in exact_match} == {"100%"}
    # `q="%"` escapado solo matchea comercios que contienen un `%` literal, no todos.
    assert {row.merchant for row in percent_only} == {"100%"}
    # `q="_"` escapado solo matchea comercios que contienen un `_` literal (no es
    # el comodin "un caracter cualquiera" de LIKE, que matchearia tambien "Rappi").
    assert {row.merchant for row in underscore_only} == {"under_score"}


async def test_find_transfer_candidates_ventana_inclusive(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    base = datetime(2026, 1, 1, tzinfo=UTC)
    account_id = uuid4()

    async with session_factory() as session:
        await SqlAlchemyLinkedAccountRepository(session).add(
            LinkedAccount(
                id=account_id,
                user_id=user.id,
                bank=Bank.BANCOLOMBIA,
                kind=AccountKind.SAVINGS,
                last4="1234",
                alias=None,
            )
        )
        await session.commit()

    async with session_factory() as session:
        repo = SqlAlchemyTransactionRepository(session)
        await repo.insert_if_absent(
            _make_tx(
                user_id=user.id,
                dedupe_key="dedupe-window-boundary",
                direction=Direction.CREDIT,
                amount="500.00",
                occurred_at=base + timedelta(hours=48),
                account_id=account_id,
            )
        )
        await repo.insert_if_absent(
            _make_tx(
                user_id=user.id,
                dedupe_key="dedupe-window-outside",
                direction=Direction.CREDIT,
                amount="500.00",
                occurred_at=base + timedelta(hours=48, seconds=1),
                account_id=account_id,
            )
        )
        await session.commit()

    async with session_factory() as session:
        repo = SqlAlchemyTransactionRepository(session)
        candidates = await repo.find_transfer_candidates(
            user.id,
            Direction.CREDIT,
            Decimal("500.00"),
            base - timedelta(hours=48),
            base + timedelta(hours=48),
        )

    assert {c.dedupe_key for c in candidates} == {"dedupe-window-boundary"}
