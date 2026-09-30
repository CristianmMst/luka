"""Tests unitarios de la cola de revision (spec 004 SS2.10, D1, F2.5)."""

from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from ledger.fakes import FakeReviewSource, FixedClock, InMemoryReviewQueueRepo, build_ledger_repos
from luka.modules.ledger.application.dto import (
    ConvertReviewCommand,
    EnqueueForReviewCommand,
    ReviewSourceView,
)
from luka.modules.ledger.application.use_cases.convert_review_item import ConvertReviewItem
from luka.modules.ledger.application.use_cases.create_manual_transaction import (
    CreateManualTransaction,
)
from luka.modules.ledger.application.use_cases.discard_review_item import DiscardReviewItem
from luka.modules.ledger.application.use_cases.enqueue_for_review import EnqueueForReview
from luka.modules.ledger.application.use_cases.get_transaction import GetTransaction
from luka.modules.ledger.application.use_cases.list_review import ListReview
from luka.modules.ledger.domain.enums import Bank, Channel, Direction
from luka.modules.ledger.domain.errors import ReviewAlreadyResolved, ReviewItemNotFound
from luka.modules.ledger.domain.review import ReviewReason, ReviewResolution
from luka.modules.ledger.events import TransactionCaptured

NOW = datetime(2024, 3, 1, 12, 0, 0, tzinfo=UTC)
USER = uuid4()


def _enqueue_cmd(
    *, raw_message_id: UUID | None = None, reason: ReviewReason = ReviewReason.LLM_LOW_CONFIDENCE
) -> EnqueueForReviewCommand:
    return EnqueueForReviewCommand(
        raw_message_id=raw_message_id or uuid4(),
        user_id=USER,
        reason=reason,
        partial_extract={"amount": "45900"},
    )


def _source_view(raw_message_id: UUID, *, received_at: datetime = NOW) -> ReviewSourceView:
    return ReviewSourceView(
        raw_message_id=raw_message_id,
        channel=Channel.EMAIL,
        bank=Bank.BANCOLOMBIA,
        sender="alertasynotificaciones@an.notificacionesbancolombia.com",
        text="Bancolombia: Compraste $45.900 en X con tu T.Deb *1234, el 01/01/2026 a las 10:00.",
        received_at=received_at,
    )


@pytest.mark.unit
async def test_enqueue_dos_veces_deja_un_solo_item() -> None:
    review_queue = InMemoryReviewQueueRepo()
    uow = (await build_ledger_repos()).uow
    use_case = EnqueueForReview(review_queue=review_queue, clock=FixedClock(NOW), uow=uow)
    cmd = _enqueue_cmd()

    await use_case.execute(cmd)
    await use_case.execute(cmd)

    items = await review_queue.list_open(USER, None, 10)
    assert len(items) == 1
    assert items[0].raw_message_id == cmd.raw_message_id
    assert items[0].reason == ReviewReason.LLM_LOW_CONFIDENCE
    assert items[0].is_open


@pytest.mark.unit
async def test_list_excluye_resueltos_y_pagina_limit_2_sobre_5() -> None:
    review_queue = InMemoryReviewQueueRepo()
    review_source = FakeReviewSource()
    uow = (await build_ledger_repos()).uow

    raw_ids = [uuid4() for _ in range(5)]
    for i, raw_id in enumerate(raw_ids):
        clock = FixedClock(NOW + timedelta(minutes=i))
        await EnqueueForReview(review_queue=review_queue, clock=clock, uow=uow).execute(
            _enqueue_cmd(raw_message_id=raw_id)
        )
        review_source.views[raw_id] = _source_view(raw_id)

    use_case = ListReview(review_queue=review_queue, review_source=review_source)
    seen: list[UUID] = []
    cursor = None
    pages = 0
    while True:
        page = await use_case.execute(USER, cursor, limit=2)
        pages += 1
        seen.extend(entry.item.raw_message_id for entry in page.items)
        if page.next_cursor is None:
            break
        cursor = page.next_cursor
        assert pages <= 10

    assert pages == 3  # 5 items abiertos, limit=2 -> 3 paginas (2 + 2 + 1)
    assert len(seen) == len(set(seen)) == 5
    assert set(raw_ids) == set(seen)
    # el mas reciente primero (created_at DESC)
    assert seen[0] == raw_ids[-1]

    # Resuelve uno y verifica que `list_open` lo excluye del resto.
    await review_queue.resolve(USER, raw_ids[0], ReviewResolution.DISCARDED, NOW)
    page = await use_case.execute(USER, None, limit=10)
    remaining = {entry.item.raw_message_id for entry in page.items}
    assert raw_ids[0] not in remaining
    assert len(remaining) == 4


def _convert_cmd(raw_message_id: UUID) -> ConvertReviewCommand:
    return ConvertReviewCommand(
        user_id=USER,
        raw_message_id=raw_message_id,
        amount=Decimal("45900"),
        direction=Direction.DEBIT,
        occurred_at=NOW,
        category_id=None,
        merchant="Panaderia",
        description=None,
        account_id=None,
        notes=None,
        kind=None,
    )


async def _build_convert_use_case(repos, review_queue, review_source) -> ConvertReviewItem:
    create_manual = CreateManualTransaction(
        transactions=repos.transactions,
        sources=repos.sources,
        categories=repos.categories,
        accounts=repos.accounts,
        events=repos.events,
        clock=FixedClock(NOW),
        ids=repos.ids,
        uow=repos.uow,
    )
    get_transaction = GetTransaction(transactions=repos.transactions, sources=repos.sources)
    return ConvertReviewItem(
        review_queue=review_queue,
        review_source=review_source,
        create_manual=create_manual,
        get_transaction=get_transaction,
        events=repos.events,
        clock=FixedClock(NOW),
        ids=repos.ids,
        uow=repos.uow,
    )


@pytest.mark.unit
async def test_convert_crea_transaccion_manual_con_fuente_del_raw_y_resuelve() -> None:
    repos = await build_ledger_repos()
    review_queue = InMemoryReviewQueueRepo()
    review_source = FakeReviewSource()
    raw_message_id = uuid4()
    received_at = NOW - timedelta(minutes=5)
    review_source.views[raw_message_id] = _source_view(raw_message_id, received_at=received_at)
    await EnqueueForReview(review_queue=review_queue, clock=FixedClock(NOW), uow=repos.uow).execute(
        _enqueue_cmd(raw_message_id=raw_message_id)
    )

    use_case = await _build_convert_use_case(repos, review_queue, review_source)
    detail = await use_case.execute(_convert_cmd(raw_message_id))

    assert detail.transaction.parsed_by == "manual"
    assert len(detail.sources) == 1
    source = detail.sources[0]
    assert source.raw_message_id == raw_message_id
    assert source.channel == Channel.EMAIL

    item = await review_queue.get(USER, raw_message_id)
    assert item is not None
    assert item.resolution == ReviewResolution.CONVERTED
    assert not item.is_open

    assert review_source.marked[raw_message_id][0] == "reviewed"

    captured = [e for e in repos.events.events if isinstance(e, TransactionCaptured)]
    assert len(captured) == 1
    assert captured[0].transaction_id == detail.transaction.id


@pytest.mark.unit
async def test_convert_dos_veces_lanza_review_already_resolved() -> None:
    repos = await build_ledger_repos()
    review_queue = InMemoryReviewQueueRepo()
    review_source = FakeReviewSource()
    raw_message_id = uuid4()
    review_source.views[raw_message_id] = _source_view(raw_message_id)
    await EnqueueForReview(review_queue=review_queue, clock=FixedClock(NOW), uow=repos.uow).execute(
        _enqueue_cmd(raw_message_id=raw_message_id)
    )
    use_case = await _build_convert_use_case(repos, review_queue, review_source)

    await use_case.execute(_convert_cmd(raw_message_id))

    with pytest.raises(ReviewAlreadyResolved):
        await use_case.execute(_convert_cmd(raw_message_id))


@pytest.mark.unit
async def test_convert_item_ajeno_o_inexistente_lanza_review_item_not_found() -> None:
    repos = await build_ledger_repos()
    review_queue = InMemoryReviewQueueRepo()
    review_source = FakeReviewSource()
    use_case = await _build_convert_use_case(repos, review_queue, review_source)

    with pytest.raises(ReviewItemNotFound):
        await use_case.execute(_convert_cmd(uuid4()))

    # Item de otro usuario: `get` filtra por user_id -> mismo error.
    raw_message_id = uuid4()
    review_source.views[raw_message_id] = _source_view(raw_message_id)
    other_user_cmd = EnqueueForReviewCommand(
        raw_message_id=raw_message_id,
        user_id=uuid4(),
        reason=ReviewReason.LLM_LOW_CONFIDENCE,
        partial_extract={},
    )
    await EnqueueForReview(review_queue=review_queue, clock=FixedClock(NOW), uow=repos.uow).execute(
        other_user_cmd
    )
    with pytest.raises(ReviewItemNotFound):
        await use_case.execute(_convert_cmd(raw_message_id))


@pytest.mark.unit
async def test_discard_resuelve_y_marca_discarded() -> None:
    review_queue = InMemoryReviewQueueRepo()
    review_source = FakeReviewSource()
    raw_message_id = uuid4()
    uow = (await build_ledger_repos()).uow
    await EnqueueForReview(review_queue=review_queue, clock=FixedClock(NOW), uow=uow).execute(
        _enqueue_cmd(raw_message_id=raw_message_id)
    )

    use_case = DiscardReviewItem(
        review_queue=review_queue, review_source=review_source, clock=FixedClock(NOW), uow=uow
    )
    item = await use_case.execute(USER, raw_message_id)

    assert item.resolution == ReviewResolution.DISCARDED
    assert item.resolved_at == NOW
    assert review_source.marked[raw_message_id][0] == "discarded"

    stored = await review_queue.get(USER, raw_message_id)
    assert stored is not None
    assert not stored.is_open


@pytest.mark.unit
async def test_discard_dos_veces_lanza_review_already_resolved() -> None:
    review_queue = InMemoryReviewQueueRepo()
    review_source = FakeReviewSource()
    raw_message_id = uuid4()
    uow = (await build_ledger_repos()).uow
    await EnqueueForReview(review_queue=review_queue, clock=FixedClock(NOW), uow=uow).execute(
        _enqueue_cmd(raw_message_id=raw_message_id)
    )
    use_case = DiscardReviewItem(
        review_queue=review_queue, review_source=review_source, clock=FixedClock(NOW), uow=uow
    )
    await use_case.execute(USER, raw_message_id)

    with pytest.raises(ReviewAlreadyResolved):
        await use_case.execute(USER, raw_message_id)
