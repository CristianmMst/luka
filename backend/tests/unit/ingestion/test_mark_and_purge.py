"""Tests unitarios de `MarkRawMessage` y `PurgeExpiredBodies` (spec 004 §6, F2.4/F3.7)."""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from finanzia.modules.ingestion.application.use_cases.mark_raw_message import MarkRawMessage
from finanzia.modules.ingestion.application.use_cases.purge_bodies import PurgeExpiredBodies
from finanzia.modules.ingestion.domain.entities import RawMessage
from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus
from ingestion.fakes import InMemoryRawMessageRepo, NoopUoW

NOW = datetime(2026, 5, 1, 12, 0, tzinfo=UTC)
USER = uuid4()


def _raw_message(*, status: RawMessageStatus = RawMessageStatus.PENDING) -> RawMessage:
    return RawMessage(
        id=uuid4(),
        user_id=USER,
        channel=Channel.EMAIL,
        external_id="mark-purge-1",
        sender="alertasynotificaciones@an.notificacionesbancolombia.com",
        bank="bancolombia",
        body="cuerpo",
        status=status,
        received_at=NOW - timedelta(days=120),
        purge_after=NOW - timedelta(days=30),
    )


@pytest.mark.unit
async def test_mark_raw_message_actualiza_estado_y_devuelve_true() -> None:
    repo = InMemoryRawMessageRepo()
    msg = _raw_message()
    await repo.insert_if_absent(msg)
    use_case = MarkRawMessage(repo=repo)

    updated = await use_case.execute(msg.id, RawMessageStatus.PARSED, NOW)

    assert updated is True
    assert repo.by_id[msg.id].status == RawMessageStatus.PARSED


@pytest.mark.unit
async def test_mark_raw_message_de_id_inexistente_devuelve_false() -> None:
    repo = InMemoryRawMessageRepo()
    use_case = MarkRawMessage(repo=repo)

    updated = await use_case.execute(uuid4(), RawMessageStatus.PARSED, NOW)

    assert updated is False


@pytest.mark.unit
async def test_purge_expired_bodies_comitea_y_devuelve_la_cantidad_purgada() -> None:
    repo = InMemoryRawMessageRepo()
    uow = NoopUoW()
    msg = _raw_message()
    await repo.insert_if_absent(msg)
    use_case = PurgeExpiredBodies(repo=repo, uow=uow)

    count = await use_case.execute(NOW)

    assert count == 1
    assert repo.by_id[msg.id].body is None
    assert uow.commits == 1
