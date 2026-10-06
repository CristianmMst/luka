"""Tests unitarios de `SplitMergedCaptures` (spec 004 SS3): separa las capturas
entre personas que el dedupe viejo fusiono (tres amigos que envian $7.100 a la
vez quedaban como un solo movimiento con tres fuentes)."""

from collections.abc import Mapping
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from ledger.fakes import FixedClock, build_ledger_repos
from luka.modules.ledger.application.dto import CapturedTransactionCommand, SourceInput
from luka.modules.ledger.application.use_cases.record_captured_transaction import (
    RecordCapturedTransaction,
)
from luka.modules.ledger.application.use_cases.split_merged_captures import (
    SplitMergedCaptures,
)
from luka.modules.ledger.domain.entities import TransactionSource
from luka.modules.ledger.domain.enums import Bank, Channel, Direction

NOW = datetime(2026, 10, 4, 7, 24, tzinfo=UTC)
USER = uuid4()
PARSED_BY = "rule:bancolombia:transferencia_llave_recibida:v1"


def _transfer(name: str, raw_id: UUID, *, minutes: int = 0) -> CapturedTransactionCommand:
    at = NOW + timedelta(minutes=minutes)
    return CapturedTransactionCommand(
        user_id=USER,
        bank=Bank.BANCOLOMBIA,
        amount=Decimal("7100"),
        direction=Direction.CREDIT,
        occurred_at=at,
        last4="8761",
        merchant=name,
        description=None,
        suggested_category_slug=None,
        parsed_by=PARSED_BY,
        confidence=None,
        source=SourceInput(Channel.EMAIL, raw_id, at),
        merchant_is_person=True,
    )


class _Reader:
    """Doble de `CaptureReaderPort`: re-parsea desde un dict precargado."""

    def __init__(self, captures: Mapping[UUID, CapturedTransactionCommand | None]) -> None:
        self._captures = captures

    async def capture_for(self, raw_message_id: UUID) -> CapturedTransactionCommand | None:
        return self._captures.get(raw_message_id)


def _record(repos) -> RecordCapturedTransaction:
    return RecordCapturedTransaction(
        transactions=repos.transactions,
        sources=repos.sources,
        categories=repos.categories,
        accounts=repos.accounts,
        merchant_rules=repos.merchant_rules,
        review_queue=repos.review_queue,
        owner_names=repos.owner_names,
        events=repos.events,
        clock=FixedClock(NOW),
        ids=repos.ids,
        uow=repos.uow,
    )


def _split(repos, reader: _Reader) -> SplitMergedCaptures:
    return SplitMergedCaptures(
        transactions=repos.transactions,
        sources=repos.sources,
        reader=reader,
        record=_record(repos),
        clock=FixedClock(NOW + timedelta(days=1)),
        uow=repos.uow,
    )


async def _merged(repos, captures: list[CapturedTransactionCommand]) -> UUID:
    """Estado del dedupe viejo: la primera captura crea el movimiento y las demas
    quedan como fuentes adjuntas a el."""
    first = await _record(repos).execute(captures[0])
    for cmd in captures[1:]:
        await repos.sources.attach(
            TransactionSource(
                id=uuid4(),
                transaction_id=first.transaction.id,
                raw_message_id=cmd.source.raw_message_id,
                channel=cmd.source.channel,
                received_at=cmd.source.received_at,
            )
        )
    return first.transaction.id


@pytest.mark.unit
async def test_separa_las_transferencias_de_contrapartes_distintas() -> None:
    repos = await build_ledger_repos()
    manuel, tomas, mariana = uuid4(), uuid4(), uuid4()
    captures = {
        manuel: _transfer("MANUEL NIETO", manuel),
        tomas: _transfer("TOMAS ALEJANDRO RODRIGUEZ COLMENARES", tomas, minutes=2),
        mariana: _transfer("MARIANA GOMEZ ABRIL", mariana, minutes=2),
    }
    original = await _merged(repos, list(captures.values()))

    summary = await _split(repos, _Reader(captures)).execute(
        person_parsed_by={PARSED_BY}, user_id=None
    )

    assert summary.split == 2
    assert summary.unreadable == 0
    assert [s.raw_message_id for s in await repos.sources.list_for(original)] == [manuel]
    tomas_tx = await repos.sources.transaction_id_for_raw_message(tomas)
    mariana_tx = await repos.sources.transaction_id_for_raw_message(mariana)
    assert len({original, tomas_tx, mariana_tx}) == 3
    assert tomas_tx is not None
    assert mariana_tx is not None
    moved = [await repos.transactions.get(USER, t) for t in (tomas_tx, mariana_tx)]
    assert [t.merchant for t in moved if t is not None] == [
        "TOMAS ALEJANDRO RODRIGUEZ COLMENARES",
        "MARIANA GOMEZ ABRIL",
    ]
    touched = await repos.transactions.get(USER, original)
    assert touched is not None
    assert touched.updated_at == NOW + timedelta(days=1)  # la app trae el cambio


@pytest.mark.unit
async def test_es_idempotente() -> None:
    repos = await build_ledger_repos()
    manuel, mariana = uuid4(), uuid4()
    captures = {
        manuel: _transfer("MANUEL NIETO", manuel),
        mariana: _transfer("MARIANA GOMEZ ABRIL", mariana, minutes=1),
    }
    await _merged(repos, list(captures.values()))
    split = _split(repos, _Reader(captures))
    await split.execute(person_parsed_by={PARSED_BY}, user_id=None)

    again = await split.execute(person_parsed_by={PARSED_BY}, user_id=None)

    assert again.split == 0


@pytest.mark.unit
async def test_no_toca_el_correo_y_la_notificacion_de_la_misma_persona() -> None:
    repos = await build_ledger_repos()
    email, notification = uuid4(), uuid4()
    captures = {
        email: _transfer("MARIANA GOMEZ ABRIL", email),
        notification: _transfer("MARIANA GOMEZ", notification),
    }
    original = await _merged(repos, list(captures.values()))

    summary = await _split(repos, _Reader(captures)).execute(
        person_parsed_by={PARSED_BY}, user_id=None
    )

    assert summary.split == 0
    assert len(await repos.sources.list_for(original)) == 2


@pytest.mark.unit
async def test_fuente_sin_cuerpo_se_cuenta_y_no_se_mueve() -> None:
    """Un cuerpo purgado (90 dias) no se puede re-parsear: la fuente se queda."""
    repos = await build_ledger_repos()
    manuel, purged = uuid4(), uuid4()
    original = await _merged(
        repos, [_transfer("MANUEL NIETO", manuel), _transfer("X", purged, minutes=1)]
    )

    summary = await _split(
        repos, _Reader({manuel: _transfer("MANUEL NIETO", manuel), purged: None})
    ).execute(person_parsed_by={PARSED_BY}, user_id=None)

    assert summary.split == 0
    assert summary.unreadable == 1
    assert len(await repos.sources.list_for(original)) == 2


@pytest.mark.unit
async def test_filtra_por_usuario() -> None:
    repos = await build_ledger_repos()
    manuel, mariana = uuid4(), uuid4()
    captures = {
        manuel: _transfer("MANUEL NIETO", manuel),
        mariana: _transfer("MARIANA GOMEZ ABRIL", mariana),
    }
    await _merged(repos, list(captures.values()))

    summary = await _split(repos, _Reader(captures)).execute(
        person_parsed_by={PARSED_BY}, user_id=uuid4()
    )

    assert summary.split == 0


@pytest.mark.unit
async def test_la_referencia_es_la_contraparte_del_movimiento_no_la_primera_fuente() -> None:
    """Si la primera fuente adjunta es de otra persona (mismo `received_at`), la
    que se queda es la del comercio del movimiento; si no, la fuente soltada se
    volveria a pegar al mismo movimiento y correrlo otra vez separaria de nuevo."""
    repos = await build_ledger_repos()
    manuel, tomas = uuid4(), uuid4()
    captures = {
        manuel: _transfer("MANUEL NIETO", manuel),
        tomas: _transfer("TOMAS ALEJANDRO RODRIGUEZ COLMENARES", tomas),
    }
    original = await _record(repos).execute(captures[manuel])
    # Fuentes en el orden contrario al del movimiento: Tomas primero.
    sources = repos.sources._by_tx[original.transaction.id]
    sources.insert(
        0,
        TransactionSource(
            id=uuid4(),
            transaction_id=original.transaction.id,
            raw_message_id=tomas,
            channel=Channel.EMAIL,
            received_at=NOW,
        ),
    )
    split = _split(repos, _Reader(captures))

    first = await split.execute(person_parsed_by={PARSED_BY}, user_id=None)
    again = await split.execute(person_parsed_by={PARSED_BY}, user_id=None)

    assert first.split == 1
    assert again.split == 0
    assert [s.raw_message_id for s in await repos.sources.list_for(original.transaction.id)] == [
        manuel
    ]
