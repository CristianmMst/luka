"""Tests de `deterministic_event_id` (D8, F2.2)."""

from uuid import uuid4

import pytest

from luka.modules.parsing.events import deterministic_event_id

pytestmark = pytest.mark.unit


def test_deterministic_event_id_es_estable_para_el_mismo_input() -> None:
    raw_message_id = uuid4()

    first = deterministic_event_id("transaction_parsed", raw_message_id)
    second = deterministic_event_id("transaction_parsed", raw_message_id)

    assert first == second


def test_deterministic_event_id_difiere_por_outcome() -> None:
    raw_message_id = uuid4()

    parsed = deterministic_event_id("transaction_parsed", raw_message_id)
    failed = deterministic_event_id("llm_low_confidence", raw_message_id)

    assert parsed != failed


def test_deterministic_event_id_difiere_por_raw_message_id() -> None:
    first = deterministic_event_id("transaction_parsed", uuid4())
    second = deterministic_event_id("transaction_parsed", uuid4())

    assert first != second
