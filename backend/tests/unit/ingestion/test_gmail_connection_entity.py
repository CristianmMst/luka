"""Tests unitarios de `GmailConnection` (spec 004 §2.3, F3.2)."""

from datetime import UTC, datetime
from uuid import uuid4

import pytest

from finanzia.modules.ingestion.domain.entities import GmailConnection
from finanzia.modules.ingestion.domain.enums import GmailConnectionStatus

NOW_AWARE = datetime(2026, 5, 1, 12, 0, tzinfo=UTC)
NOW_NAIVE = datetime(2026, 5, 1, 12, 0)


def _connection(**overrides: object) -> GmailConnection:
    defaults: dict[str, object] = {
        "user_id": uuid4(),
        "email": "ana@example.com",
        "refresh_token_enc": b"nonce-y-ciphertext",
        "history_id": None,
        "watch_expires_at": None,
        "status": GmailConnectionStatus.ACTIVE,
        "last_sync_at": None,
        "created_at": NOW_AWARE,
        "updated_at": NOW_AWARE,
    }
    defaults.update(overrides)
    return GmailConnection(**defaults)  # type: ignore[arg-type]


@pytest.mark.unit
def test_conexion_valida_se_construye_sin_error() -> None:
    connection = _connection()

    assert connection.status is GmailConnectionStatus.ACTIVE
    assert connection.history_id is None


@pytest.mark.unit
def test_created_at_naive_lanza_value_error() -> None:
    with pytest.raises(ValueError, match="tz-aware"):
        _connection(created_at=NOW_NAIVE)


@pytest.mark.unit
def test_updated_at_naive_lanza_value_error() -> None:
    with pytest.raises(ValueError, match="tz-aware"):
        _connection(updated_at=NOW_NAIVE)


@pytest.mark.unit
def test_watch_expires_at_naive_lanza_value_error() -> None:
    with pytest.raises(ValueError, match="tz-aware"):
        _connection(watch_expires_at=NOW_NAIVE)


@pytest.mark.unit
def test_last_sync_at_naive_lanza_value_error() -> None:
    with pytest.raises(ValueError, match="tz-aware"):
        _connection(last_sync_at=NOW_NAIVE)


@pytest.mark.unit
def test_watch_expires_at_y_last_sync_at_pueden_ser_none() -> None:
    connection = _connection(watch_expires_at=None, last_sync_at=None)

    assert connection.watch_expires_at is None
    assert connection.last_sync_at is None


@pytest.mark.unit
def test_es_inmutable() -> None:
    connection = _connection()

    with pytest.raises(AttributeError):
        connection.status = GmailConnectionStatus.REVOKED  # type: ignore[misc]
