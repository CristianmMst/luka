"""Tests unitarios de `BusEventPublisher`: publicacion fail-soft (review final)."""

from dataclasses import dataclass
from typing import ClassVar
from uuid import UUID, uuid4

import pytest
import structlog.testing

from luka.modules.ledger.infrastructure.event_publisher import BusEventPublisher


@dataclass(frozen=True, slots=True)
class _FakeEvent:
    event_id: UUID
    payload: str

    event_type: ClassVar[str] = "ledger.FakeEvent"


class _WorkingBus:
    def __init__(self) -> None:
        self.published: list[object] = []

    async def publish(self, event: object) -> None:
        self.published.append(event)


class _FailingBus:
    async def publish(self, event: object) -> None:
        raise ConnectionError("redis unreachable")


@pytest.mark.unit
async def test_publish_con_bus_que_falla_no_propaga_y_registra_warning() -> None:
    event = _FakeEvent(event_id=uuid4(), payload="dato-sensible-que-no-debe-loguearse")
    publisher = BusEventPublisher(_FailingBus())

    with structlog.testing.capture_logs() as captured:
        await publisher.publish(event)  # no debe lanzar

    assert len(captured) == 1
    entry = captured[0]
    assert entry["event"] == "event_publish_failed"
    assert entry["log_level"] == "warning"
    assert entry["event_type"] == "ledger.FakeEvent"
    assert entry["event_id"] == event.event_id
    assert "payload" not in entry
    assert "dato-sensible-que-no-debe-loguearse" not in str(entry)


@pytest.mark.unit
async def test_publish_con_bus_operativo_entrega_el_evento() -> None:
    bus = _WorkingBus()
    publisher = BusEventPublisher(bus)
    event = _FakeEvent(event_id=uuid4(), payload="ok")

    await publisher.publish(event)

    assert bus.published == [event]


@pytest.mark.unit
async def test_publish_timeout_error_tambien_es_fail_soft() -> None:
    class _TimeoutBus:
        async def publish(self, event: object) -> None:
            raise TimeoutError("timed out")

    publisher = BusEventPublisher(_TimeoutBus())
    event = _FakeEvent(event_id=uuid4(), payload="ok")

    with structlog.testing.capture_logs() as captured:
        await publisher.publish(event)

    assert len(captured) == 1
    assert captured[0]["event"] == "event_publish_failed"
