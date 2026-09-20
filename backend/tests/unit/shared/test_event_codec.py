"""Tests del codec de eventos: roundtrip, tipos y errores (spec 003 SS2.3, F1.8)."""

import re
from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4

import pytest

from finanzia.modules.identity.events import UserDeleted
from finanzia.modules.ledger.domain.enums import Direction, FiscalTag, Kind
from finanzia.modules.ledger.events import TransactionCaptured
from finanzia.shared.events.codec import EventRegistry, UnknownEventType

pytestmark = pytest.mark.unit


def _make_transaction_captured() -> TransactionCaptured:
    return TransactionCaptured(
        event_id=uuid4(),
        occurred_at=datetime(2026, 9, 18, 12, 0, 0, tzinfo=UTC),
        user_id=uuid4(),
        transaction_id=uuid4(),
        kind=Kind.EXPENSE,
        fiscal_tag=FiscalTag.NO_DEDUCIBLE,
        amount=Decimal("152300.00"),
        direction=Direction.DEBIT,
        category_id=uuid4(),
        transaction_occurred_at=datetime(2026, 9, 17, 8, 30, 0, tzinfo=UTC),
        created=True,
    )


def _make_user_deleted() -> UserDeleted:
    return UserDeleted(
        event_id=uuid4(), occurred_at=datetime(2026, 9, 18, 12, 0, 0, tzinfo=UTC), user_id=uuid4()
    )


@pytest.fixture
def registry() -> EventRegistry:
    reg = EventRegistry()
    reg.register(TransactionCaptured)
    reg.register(UserDeleted)
    return reg


def test_roundtrip_transaction_captured_preserva_tipos_exactos(registry: EventRegistry) -> None:
    event = _make_transaction_captured()

    fields = registry.encode(event)
    decoded = registry.decode(fields)

    assert decoded == event
    assert isinstance(decoded.amount, Decimal)  # type: ignore[union-attr]
    assert decoded.amount == Decimal("152300.00")  # type: ignore[union-attr]
    assert decoded.occurred_at.tzinfo is not None  # type: ignore[union-attr]
    assert decoded.occurred_at.utcoffset().total_seconds() == 0  # type: ignore[union-attr]
    assert decoded.kind is Kind.EXPENSE  # type: ignore[union-attr]
    assert decoded.fiscal_tag is FiscalTag.NO_DEDUCIBLE  # type: ignore[union-attr]
    assert decoded.direction is Direction.DEBIT  # type: ignore[union-attr]
    assert decoded.created is True  # type: ignore[union-attr]
    assert isinstance(decoded.created, bool)  # type: ignore[union-attr]


def test_roundtrip_user_deleted(registry: EventRegistry) -> None:
    event = _make_user_deleted()

    fields = registry.encode(event)
    decoded = registry.decode(fields)

    assert decoded == event


def test_encode_produce_solo_strings(registry: EventRegistry) -> None:
    fields = registry.encode(_make_transaction_captured())

    assert set(fields) == {"event_id", "event_type", "occurred_at", "payload"}
    assert all(isinstance(value, str) for value in fields.values())
    assert fields["event_type"] == "ledger.TransactionCaptured"


def test_decode_acepta_claves_y_valores_bytes(registry: EventRegistry) -> None:
    event = _make_transaction_captured()
    fields = registry.encode(event)
    bytes_fields = {key.encode(): value.encode() for key, value in fields.items()}

    decoded = registry.decode(bytes_fields)

    assert decoded == event


def test_decode_event_type_desconocido_levanta_unknown_event_type(
    registry: EventRegistry,
) -> None:
    fields = registry.encode(_make_transaction_captured())
    fields["event_type"] = "ledger.NoExiste"

    with pytest.raises(UnknownEventType):
        registry.decode(fields)


def test_get_event_type_desconocido_levanta_unknown_event_type(registry: EventRegistry) -> None:
    with pytest.raises(UnknownEventType):
        registry.get("ledger.NoExiste")


def test_registrar_dos_veces_la_misma_clase_es_no_op(registry: EventRegistry) -> None:
    registry.register(TransactionCaptured)  # no debe levantar

    assert registry.get("ledger.TransactionCaptured") is TransactionCaptured


def test_registrar_event_type_duplicado_con_otra_clase_levanta_value_error(
    registry: EventRegistry,
) -> None:
    class _Impostor:
        event_type = "ledger.TransactionCaptured"

    with pytest.raises(ValueError, match=re.escape("ledger.TransactionCaptured")):
        registry.register(_Impostor)


def test_register_usable_como_decorador() -> None:
    fresh_registry = EventRegistry()

    @fresh_registry.register
    class _Standalone:
        event_type = "test.Standalone"

    assert fresh_registry.get("test.Standalone") is _Standalone
