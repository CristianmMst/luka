"""Tests unitarios de `RequeuePendingRawMessages` (riesgo 4 / D9, F3.7 adelantado
en F2 - Task 10): republica `RawMessageReceived` para filas `pending` huerfanas y
las "toca" (`touch`) para no volver a republicarlas dentro de la misma ventana.
"""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from support.clock import FixedClock

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
    *, external_id: str, status: RawMessageStatus = RawMessageStatus.PENDING
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

    count = await use_case.execute()

    assert count == 1
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
    await repo.touch(msg.id, NOW - timedelta(minutes=5))
    use_case = RequeuePendingRawMessages(
        repo=repo, events=events, clock=FixedClock(NOW), ids=SequenceIdGenerator(), uow=NoopUoW()
    )

    count = await use_case.execute(older_than=timedelta(minutes=10))

    assert count == 0
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

    count = await use_case.execute()

    assert count == 0
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

    assert first == 1
    assert second == 0
    assert len(events.events) == 1
