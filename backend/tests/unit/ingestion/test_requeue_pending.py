"""Tests unitarios de `RequeuePendingRawMessages` (riesgo 4 / D9, F3.7 adelantado
en F2 - Task 10): republica `RawMessageReceived` para filas `pending` huerfanas,
las marca (`mark_requeued`) para no volver a republicarlas dentro de la misma
ventana y deja de reencolar (pasandolas a `failed`) las que ya superaron el
maximo de republicaciones.
"""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from support.clock import FixedClock

from finanzia.modules.ingestion.application.dto import RequeueSummary
from finanzia.modules.ingestion.application.use_cases.requeue_pending import (
    RequeuePendingRawMessages,
)
from finanzia.modules.ingestion.domain.entities import RawMessage
from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus
from finanzia.modules.ingestion.events import RawMessageReceived
from ingestion.fakes import InMemoryRawMessageRepo, NoopUoW, RecordingPublisher, SequenceIdGenerator

NOW = datetime(2026, 5, 1, 12, 0, tzinfo=UTC)
USER = uuid4()


def _raw_message(
    *,
    external_id: str,
    status: RawMessageStatus = RawMessageStatus.PENDING,
    requeue_attempts: int = 0,
) -> RawMessage:
    return RawMessage(
        id=uuid4(),
        user_id=USER,
        channel=Channel.EMAIL,
        external_id=external_id,
        sender="alertasynotificaciones@an.notificacionesbancolombia.com",
        bank="bancolombia",
        body="cuerpo",
        status=status,
        received_at=NOW - timedelta(days=1),
        purge_after=NOW + timedelta(days=89),
        requeue_attempts=requeue_attempts,
    )


@pytest.mark.unit
async def test_republica_solo_pending_no_tocados_y_comitea_una_vez() -> None:
    repo = InMemoryRawMessageRepo()
    events = RecordingPublisher()
    uow = NoopUoW()
    msg = _raw_message(external_id="requeue-1")
    await repo.insert_if_absent(msg)
    use_case = RequeuePendingRawMessages(
        repo=repo, events=events, clock=FixedClock(NOW), ids=SequenceIdGenerator(), uow=uow
    )

    summary = await use_case.execute()

    assert summary.requeued == 1
    assert summary.exhausted == 0
    assert len(events.events) == 1
    published = events.events[0]
    assert isinstance(published, RawMessageReceived)
    assert published.raw_message_id == msg.id
    assert published.user_id == USER
    assert published.channel == "email"
    assert published.bank == "bancolombia"
    assert uow.commits == 1


@pytest.mark.unit
async def test_no_republica_filas_ya_tocadas_dentro_de_la_ventana() -> None:
    repo = InMemoryRawMessageRepo()
    events = RecordingPublisher()
    msg = _raw_message(external_id="requeue-2")
    await repo.insert_if_absent(msg)
    await repo.mark_requeued(msg.id, NOW - timedelta(minutes=5))
    use_case = RequeuePendingRawMessages(
        repo=repo, events=events, clock=FixedClock(NOW), ids=SequenceIdGenerator(), uow=NoopUoW()
    )

    summary = await use_case.execute(older_than=timedelta(minutes=10))

    assert summary.requeued == 0
    assert events.events == []


@pytest.mark.unit
async def test_no_republica_filas_que_no_estan_pending() -> None:
    repo = InMemoryRawMessageRepo()
    events = RecordingPublisher()
    msg = _raw_message(external_id="requeue-3", status=RawMessageStatus.PARSED)
    await repo.insert_if_absent(msg)
    use_case = RequeuePendingRawMessages(
        repo=repo, events=events, clock=FixedClock(NOW), ids=SequenceIdGenerator(), uow=NoopUoW()
    )

    summary = await use_case.execute()

    assert summary.requeued == 0
    assert events.events == []


@pytest.mark.unit
async def test_segunda_corrida_inmediata_no_vuelve_a_contar_lo_ya_republicado() -> None:
    repo = InMemoryRawMessageRepo()
    events = RecordingPublisher()
    msg = _raw_message(external_id="requeue-4")
    await repo.insert_if_absent(msg)
    use_case = RequeuePendingRawMessages(
        repo=repo, events=events, clock=FixedClock(NOW), ids=SequenceIdGenerator(), uow=NoopUoW()
    )

    first = await use_case.execute()
    second = await use_case.execute()

    assert first.requeued == 1
    assert second.requeued == 0
    assert len(events.events) == 1


@pytest.mark.unit
async def test_fila_que_supero_el_maximo_de_republicaciones_pasa_a_failed() -> None:
    """Cota del ciclo cron -> DLQ -> sigue `pending` -> cron (riesgo 4 / D9)."""
    repo = InMemoryRawMessageRepo()
    events = RecordingPublisher()
    msg = _raw_message(external_id="requeue-5", requeue_attempts=5)
    await repo.insert_if_absent(msg)
    use_case = RequeuePendingRawMessages(
        repo=repo, events=events, clock=FixedClock(NOW), ids=SequenceIdGenerator(), uow=NoopUoW()
    )

    summary = await use_case.execute(max_attempts=5)

    assert summary == RequeueSummary(requeued=0, exhausted=1)
    assert events.events == []
    stored = await repo.get(msg.id)
    assert stored is not None
    assert stored.status is RawMessageStatus.FAILED


@pytest.mark.unit
async def test_reencola_hasta_el_maximo_y_despues_agota() -> None:
    repo = InMemoryRawMessageRepo()
    events = RecordingPublisher()
    msg = _raw_message(external_id="requeue-6")
    await repo.insert_if_absent(msg)
    use_case = RequeuePendingRawMessages(
        repo=repo, events=events, clock=FixedClock(NOW), ids=SequenceIdGenerator(), uow=NoopUoW()
    )

    # Ventana negativa: cada corrida vuelve a ver la fila recien marcada con el
    # reloj fijo del test (en produccion el cron corre cada 15 min con una
    # ventana de 10, asi que entre corridas siempre pasa tiempo real).
    summaries = [
        await use_case.execute(older_than=timedelta(seconds=-1), max_attempts=3) for _ in range(4)
    ]

    assert [s.requeued for s in summaries] == [1, 1, 1, 0]
    assert [s.exhausted for s in summaries] == [0, 0, 0, 1]
    assert len(events.events) == 3
    stored = await repo.get(msg.id)
    assert stored is not None
    assert stored.status is RawMessageStatus.FAILED
