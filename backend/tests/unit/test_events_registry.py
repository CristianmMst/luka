"""Tests del composition root de eventos: registro y grupos de consumidores (F2.2)."""

import pytest

from finanzia.events_registry import CONSUMER_GROUPS, build_registry
from finanzia.modules.identity.events import UserDeleted
from finanzia.modules.ingestion.events import RawMessageReceived
from finanzia.modules.ledger.events import TransactionCaptured
from finanzia.modules.parsing.events import ParseFailed, TransactionParsed

pytestmark = pytest.mark.unit


def test_build_registry_registra_los_5_tipos_de_evento() -> None:
    registry = build_registry()

    assert registry.get("ledger.TransactionCaptured") is TransactionCaptured
    assert registry.get("identity.UserDeleted") is UserDeleted
    assert registry.get("ingestion.RawMessageReceived") is RawMessageReceived
    assert registry.get("parsing.TransactionParsed") is TransactionParsed
    assert registry.get("parsing.ParseFailed") is ParseFailed


def test_consumer_groups_tiene_4_entradas_unicas() -> None:
    assert len(CONSUMER_GROUPS) == 4
    assert len(set(CONSUMER_GROUPS)) == 4


def test_consumer_groups_contenido_exacto() -> None:
    assert CONSUMER_GROUPS == (
        ("ingestion.RawMessageReceived", "parsing"),
        ("parsing.TransactionParsed", "ledger"),
        ("parsing.ParseFailed", "ledger-review"),
        ("ledger.TransactionCaptured", "ledger-observer"),
    )
