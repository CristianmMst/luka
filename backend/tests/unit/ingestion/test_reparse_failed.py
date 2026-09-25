"""Tests unitarios de `ReparseFailedRawMessages` (spec 005 §7, spec 006 §4.4): vuelve
a `pending` los `raw_messages` `failed` con cuerpo y republica `RawMessageReceived`
para que `parsing` los procese otra vez.
"""

from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest
from support.clock import FixedClock

from finanzia.modules.ingestion.application.dto import ReparseSummary
from finanzia.modules.ingestion.application.use_cases.reparse_failed import (
    ReparseFailedRawMessages,
)
from finanzia.modules.ingestion.domain.entities import RawMessage
from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus
from finanzia.modules.ingestion.events import RawMessageReceived
from ingestion.fakes import InMemoryRawMessageRepo, NoopUoW, RecordingPublisher, SequenceIdGenerator

NOW = datetime(2026, 9, 24, 12, 0, tzinfo=UTC)
USER = uuid4()
OTHER_USER = uuid4()


def _raw_message(  # noqa: PLR0913 - builder de test, un default por campo
    *,
    external_id: str,
    status: RawMessageStatus = RawMessageStatus.FAILED,
    body: str | None = "cuerpo",
    user_id: UUID = USER,
    received_at: datetime = NOW - timedelta(days=1),
    requeue_attempts: int = 0,
) -> RawMessage:
    return RawMessage(
        id=uuid4(),
        user_id=user_id,
        channel=Channel.EMAIL,
        external_id=external_id,
        sender="alertasynotificaciones@an.notificacionesbancolombia.com",
        bank="bancolombia",
        body=body,
        status=status,
        received_at=received_at,
        purge_after=received_at + timedelta(days=90),
        requeue_attempts=requeue_attempts,
    )


class _CommitCheckingPublisher(RecordingPublisher):
    """Anota cuantos commits habia al publicar cada evento."""

    def __init__(self, uow: NoopUoW) -> None:
        super().__init__()
        self._uow = uow
        self.commits_at_publish: list[int] = []

    async def publish(self, event: object) -> None:
        self.commits_at_publish.append(self._uow.commits)
        await super().publish(event)


def _use_case(
    repo: InMemoryRawMessageRepo, events: RecordingPublisher, uow: NoopUoW
) -> ReparseFailedRawMessages:
    return ReparseFailedRawMessages(
        repo=repo, events=events, clock=FixedClock(NOW), ids=SequenceIdGenerator(), uow=uow
    )


@pytest.mark.unit
async def test_fallido_con_cuerpo_vuelve_a_pending_y_se_republica_tras_el_commit() -> None:
    repo = InMemoryRawMessageRepo()
    uow = NoopUoW()
    events = _CommitCheckingPublisher(uow)
    msg = _raw_message(external_id="reparse-1", requeue_attempts=5)
    await repo.insert_if_absent(msg)

    summary = await _use_case(repo, events, uow).execute()

    assert summary == ReparseSummary(reparsed=1)
    stored = await repo.get(msg.id)
    assert stored is not None
    assert stored.status is RawMessageStatus.PENDING
    # Cupo nuevo del cron de reencolado: si el publish se pierde, el cron la toma.
    assert stored.requeue_attempts == 0
    assert len(events.events) == 1
    published = events.events[0]
    assert isinstance(published, RawMessageReceived)
    assert published.raw_message_id == msg.id
    assert published.user_id == USER
    assert published.channel == "email"
    assert published.bank == "bancolombia"
    assert published.received_at == msg.received_at
    # Publicar antes del commit dejaria a parsing leer la fila aun `failed` (Skipped).
    assert events.commits_at_publish == [1]


@pytest.mark.unit
async def test_salta_cuerpos_purgados_y_filas_que_no_estan_failed() -> None:
    repo = InMemoryRawMessageRepo()
    uow = NoopUoW()
    events = RecordingPublisher()
    purgado = _raw_message(external_id="reparse-purgado", body=None)
    parseado = _raw_message(external_id="reparse-parsed", status=RawMessageStatus.PARSED)
    revisado = _raw_message(external_id="reparse-reviewed", status=RawMessageStatus.REVIEWED)
    for msg in (purgado, parseado, revisado):
        await repo.insert_if_absent(msg)

    summary = await _use_case(repo, events, uow).execute()

    assert summary.reparsed == 0
    assert events.events == []
    stored = await repo.get(purgado.id)
    assert stored is not None
    assert stored.status is RawMessageStatus.FAILED


@pytest.mark.unit
async def test_filtra_por_usuario_y_por_fecha_de_recepcion() -> None:
    repo = InMemoryRawMessageRepo()
    uow = NoopUoW()
    events = RecordingPublisher()
    since = NOW - timedelta(days=3)
    nuevo = _raw_message(external_id="reparse-nuevo")
    viejo = _raw_message(external_id="reparse-viejo", received_at=NOW - timedelta(days=10))
    ajeno = _raw_message(external_id="reparse-ajeno", user_id=OTHER_USER)
    for msg in (nuevo, viejo, ajeno):
        await repo.insert_if_absent(msg)

    summary = await _use_case(repo, events, uow).execute(user_id=USER, since=since)

    assert summary.reparsed == 1
    assert [e.raw_message_id for e in events.events] == [nuevo.id]  # type: ignore[attr-defined]


@pytest.mark.unit
async def test_respeta_el_limite() -> None:
    repo = InMemoryRawMessageRepo()
    uow = NoopUoW()
    events = RecordingPublisher()
    for i in range(3):
        await repo.insert_if_absent(_raw_message(external_id=f"reparse-limite-{i}"))

    summary = await _use_case(repo, events, uow).execute(limit=2)

    assert summary.reparsed == 2
    assert len(events.events) == 2


@pytest.mark.unit
async def test_segunda_corrida_no_republica_lo_ya_reencolado() -> None:
    repo = InMemoryRawMessageRepo()
    uow = NoopUoW()
    events = RecordingPublisher()
    await repo.insert_if_absent(_raw_message(external_id="reparse-dos-veces"))
    use_case = _use_case(repo, events, uow)

    first = await use_case.execute()
    second = await use_case.execute()

    assert (first.reparsed, second.reparsed) == (1, 0)
    assert len(events.events) == 1


@pytest.mark.unit
async def test_no_publica_si_la_fila_dejo_de_estar_failed_entre_la_lectura_y_el_update() -> None:
    """Carrera con un convert/discard del usuario: el UPDATE condicional pierde."""
    repo = InMemoryRawMessageRepo()
    uow = NoopUoW()
    events = RecordingPublisher()
    msg = _raw_message(external_id="reparse-carrera")
    await repo.insert_if_absent(msg)
    original_list = repo.list_failed_for_reparse

    async def list_then_review(**kwargs: object) -> list[RawMessage]:
        rows = await original_list(**kwargs)  # type: ignore[arg-type]
        await repo.set_status(msg.id, RawMessageStatus.REVIEWED, NOW)
        return rows

    repo.list_failed_for_reparse = list_then_review  # type: ignore[method-assign]

    summary = await _use_case(repo, events, uow).execute()

    assert summary.reparsed == 0
    assert events.events == []
    stored = await repo.get(msg.id)
    assert stored is not None
    assert stored.status is RawMessageStatus.REVIEWED
