"""Tests unitarios de `ListTransactions` (spec 005 SS1/SS6: paginacion por cursor)."""

from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from finanzia.modules.ledger.application.dto import Filters, ManualTransactionCommand
from finanzia.modules.ledger.application.use_cases.create_manual_transaction import (
    CreateManualTransaction,
)
from finanzia.modules.ledger.application.use_cases.list_transactions import ListTransactions
from finanzia.modules.ledger.domain.enums import Bank, Direction, Kind
from ledger.fakes import FixedClock, build_ledger_repos

NOW = datetime(2024, 3, 1, 12, 0, 0, tzinfo=UTC)
USER = uuid4()


async def _create_manual(  # noqa: PLR0913 - builder de comando con un default por campo
    repos,
    *,
    occurred_at: datetime,
    direction: Direction = Direction.DEBIT,
    category_id: UUID | None = None,
    merchant: str | None = None,
    description: str | None = None,
    now: datetime | None = None,
):
    use_case = CreateManualTransaction(
        transactions=repos.transactions,
        sources=repos.sources,
        categories=repos.categories,
        accounts=repos.accounts,
        events=repos.events,
        clock=FixedClock(now or occurred_at),
        ids=repos.ids,
        uow=repos.uow,
    )
    return await use_case.execute(
        ManualTransactionCommand(
            user_id=USER,
            amount=Decimal("10000"),
            direction=direction,
            occurred_at=occurred_at,
            category_id=category_id,
            merchant=merchant,
            description=description,
            account_id=None,
            notes=None,
        )
    )


@pytest.mark.unit
async def test_limit_2_sobre_5_transacciones_recorre_tres_paginas_sin_solapes() -> None:
    repos = await build_ledger_repos()
    created = []
    for i in range(5):
        created.append(await _create_manual(repos, occurred_at=NOW + timedelta(minutes=i)))
    use_case = ListTransactions(transactions=repos.transactions)

    seen_ids = []
    cursor = None
    pages = 0
    while True:
        page = await use_case.execute(USER, Filters(), cursor, limit=2)
        pages += 1
        seen_ids.extend(t.id for t in page.items)
        if page.next_cursor is None:
            break
        cursor = page.next_cursor
        assert pages <= 10  # corta cualquier bucle infinito si algo esta mal

    assert pages == 3
    assert len(seen_ids) == len(set(seen_ids)) == 5
    assert {t.id for t in created} == set(seen_ids)
    # orden esperado: occurred_at DESC -> el mas reciente primero
    assert seen_ids[0] == created[-1].id


@pytest.mark.unit
async def test_updated_since_pagina_en_orden_ascendente() -> None:
    repos = await build_ledger_repos()
    first = await _create_manual(repos, occurred_at=NOW, now=NOW)
    second = await _create_manual(
        repos, occurred_at=NOW + timedelta(minutes=1), now=NOW + timedelta(minutes=1)
    )
    use_case = ListTransactions(transactions=repos.transactions)

    page = await use_case.execute(
        USER, Filters(updated_since=NOW - timedelta(seconds=1)), None, limit=10
    )

    assert [t.id for t in page.items] == [first.id, second.id]
    assert page.next_cursor is None


@pytest.mark.unit
async def test_filtra_por_kind_categoria_banco_y_texto() -> None:
    repos = await build_ledger_repos()
    mercado = await repos.categories.get_system_by_slug("mercado")
    nomina = await repos.categories.get_system_by_slug("nomina")
    assert mercado is not None
    assert nomina is not None
    expense = await _create_manual(
        repos,
        occurred_at=NOW,
        direction=Direction.DEBIT,
        merchant="Panaderia Central",
        category_id=mercado.id,
    )
    income = await _create_manual(
        repos,
        occurred_at=NOW + timedelta(minutes=1),
        direction=Direction.CREDIT,
        category_id=nomina.id,
    )
    use_case = ListTransactions(transactions=repos.transactions)

    by_kind = await use_case.execute(USER, Filters(kind=Kind.INCOME), None, limit=10)
    assert [t.id for t in by_kind.items] == [income.id]

    by_category = await use_case.execute(
        USER, Filters(category_id=expense.category_id), None, limit=10
    )
    assert expense.id in [t.id for t in by_category.items]
    assert income.id not in [t.id for t in by_category.items]

    by_bank = await use_case.execute(USER, Filters(bank=Bank.OTHER), None, limit=10)
    assert by_bank.items == ()  # las manuales no tienen banco propio salvo por cuenta

    by_text = await use_case.execute(USER, Filters(q="panaderia"), None, limit=10)
    assert [t.id for t in by_text.items] == [expense.id]
