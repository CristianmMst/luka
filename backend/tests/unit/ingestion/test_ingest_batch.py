"""Tests unitarios de `IngestNotificationsBatch` (spec 006 §3.2, D9, F4.3)."""

from datetime import UTC, datetime
from uuid import uuid4

import pytest

from finanzia.modules.ingestion.application.dto import (
    BankDecision,
    BatchResult,
    NotificationItemInput,
)
from finanzia.modules.ingestion.application.use_cases.ingest_notifications_batch import (
    IngestNotificationsBatch,
)
from finanzia.modules.ingestion.application.use_cases.ingest_raw_message import IngestRawMessage
from finanzia.modules.ingestion.domain.enums import Channel
from ingestion.fakes import (
    FakeSenderPolicy,
    FixedClock,
    InMemoryRawMessageRepo,
    NoopUoW,
    RecordingPublisher,
    SequenceIdGenerator,
)

NOW = datetime(2026, 5, 1, 12, 0, tzinfo=UTC)
USER = uuid4()


def _item(client_hash: str, *, package: str = "com.bancolombia.app") -> NotificationItemInput:
    return NotificationItemInput(
        package=package,
        channel=Channel.NOTIFICATION,
        posted_at=NOW,
        title=None,
        text="Compraste $100",
        client_hash=client_hash,
    )


@pytest.mark.unit
async def test_batch_3_ok_1_duplicado_1_paquete_desconocido() -> None:
    decision = BankDecision(accepted=True, bank="bancolombia")
    policy = FakeSenderPolicy(notification_map={("com.bancolombia.app", "notification"): decision})
    repo = InMemoryRawMessageRepo()
    events = RecordingPublisher()
    uow = NoopUoW()
    ingest = IngestRawMessage(
        repo=repo,
        policy=policy,
        events=events,
        clock=FixedClock(NOW),
        ids=SequenceIdGenerator(),
        uow=uow,
    )
    batch = IngestNotificationsBatch(ingest=ingest)

    items = [
        _item("a" * 64),
        _item("b" * 64),
        _item("c" * 64),
        _item("c" * 64),  # duplicado del anterior (mismo client_hash)
        _item("d" * 64, package="com.desconocido"),
    ]

    result = await batch.execute(USER, items)

    assert result == BatchResult(accepted=3, duplicates=1, discarded=1)
    # Un commit por item aceptado (nunca en duplicado/descartado, ver ruling 4).
    assert uow.commits == 3
    # 3 aceptados + 1 republicado por el duplicado pending = 4 eventos.
    assert len(events.events) == 4
    assert len(repo.by_id) == 3
