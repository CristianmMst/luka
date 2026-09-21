"""Tests unitarios de `RawMessage` (spec 004 §2.7)."""

from datetime import UTC, datetime
from uuid import uuid4

import pytest

from finanzia.modules.ingestion.domain.entities import RawMessage
from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus

NOW_NAIVE = datetime(2026, 5, 1, 12, 0)


def _raw_message(**overrides: object) -> RawMessage:
    defaults: dict[str, object] = {
        "id": uuid4(),
        "user_id": uuid4(),
        "channel": Channel.EMAIL,
        "external_id": "msg-1",
        "sender": "alertas@bancolombia.com.co",
        "bank": "bancolombia",
        "body": "cuerpo",
        "status": RawMessageStatus.PENDING,
        "received_at": NOW_NAIVE,
        "purge_after": NOW_NAIVE,
    }
    defaults.update(overrides)
    return RawMessage(**defaults)  # type: ignore[arg-type]


@pytest.mark.unit
def test_received_at_naive_lanza_value_error() -> None:
    with pytest.raises(ValueError, match="tz-aware"):
        _raw_message()


@pytest.mark.unit
def test_purge_after_naive_lanza_value_error() -> None:
    aware = NOW_NAIVE.replace(tzinfo=UTC)
    with pytest.raises(ValueError, match="tz-aware"):
        _raw_message(received_at=aware, purge_after=NOW_NAIVE)
