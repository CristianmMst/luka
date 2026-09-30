"""Tests del composition root de eventos: registro y grupos de consumidores (F2.2)."""

import pytest

from luka.events_registry import CONSUMER_GROUPS, build_registry
from luka.modules.identity.events import UserDeleted
from luka.modules.ingestion.events import RawMessageReceived
from luka.modules.ledger.events import TransactionCaptured, TransactionDeleted
from luka.modules.parsing.events import ParseFailed, TransactionParsed
from luka.modules.recurring.events import PaymentDueSoon

pytestmark = pytest.mark.unit


def test_build_registry_registra_los_7_tipos_de_evento() -> None:
    registry = build_registry()

    assert registry.get("ledger.TransactionCaptured") is TransactionCaptured
    assert registry.get("ledger.TransactionDeleted") is TransactionDeleted
    assert registry.get("identity.UserDeleted") is UserDeleted
    assert registry.get("ingestion.RawMessageReceived") is RawMessageReceived
    assert registry.get("parsing.TransactionParsed") is TransactionParsed
    assert registry.get("parsing.ParseFailed") is ParseFailed
    assert registry.get("recurring.PaymentDueSoon") is PaymentDueSoon


def test_consumer_groups_tiene_7_entradas_unicas() -> None:
    assert len(CONSUMER_GROUPS) == 7
    assert len(set(CONSUMER_GROUPS)) == 7


def test_consumer_groups_contenido_exacto() -> None:
    assert CONSUMER_GROUPS == (
        ("ingestion.RawMessageReceived", "parsing"),
        ("parsing.TransactionParsed", "ledger"),
        ("parsing.ParseFailed", "ledger-review"),
        ("ledger.TransactionCaptured", "ledger-observer"),
        ("ledger.TransactionCaptured", "recurring"),
        ("ledger.TransactionDeleted", "recurring"),
        ("recurring.PaymentDueSoon", "notifications"),
    )
