"""Tests de integracion del bus de eventos (spec 003 SS2.3, F1.8).

Cada test usa un `prefix` unico (`test:{uuid4()}`) para no interferir entre si, aun
compartiendo la misma Redis de test (db 1, `redis_clean`). El consumidor se maneja
siempre con `asyncio.create_task(consumer.run(stop))` + `stop.set()` acotado a un
`block_ms` corto, para que las pruebas terminen rapido y sin tareas colgadas.
"""

import asyncio
from collections.abc import Awaitable, Callable
from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4

import pytest
import redis.asyncio as redis_asyncio
import redis.exceptions

from luka.modules.ledger.domain.enums import Direction, FiscalTag, Kind
from luka.modules.ledger.events import TransactionCaptured
from luka.shared.events.codec import EventRegistry
from luka.shared.events.consumer import StreamConsumer
from luka.shared.events.memory import InMemoryEventBus
from luka.shared.events.redis_streams import RedisStreamsEventBus
from luka.shared.settings import Settings

pytestmark = pytest.mark.integration

_POLL_TIMEOUT_S = 5.0
_POLL_INTERVAL_S = 0.05
_EVENT_TYPE = TransactionCaptured.event_type


def _make_event() -> TransactionCaptured:
    return TransactionCaptured(
        event_id=uuid4(),
        occurred_at=datetime.now(UTC),
        user_id=uuid4(),
        transaction_id=uuid4(),
        kind=Kind.EXPENSE,
        fiscal_tag=FiscalTag.NO_DEDUCIBLE,
        amount=Decimal("152300.00"),
        direction=Direction.DEBIT,
        category_id=uuid4(),
        transaction_occurred_at=datetime.now(UTC),
        created=True,
    )


async def _poll_until(
    check: Callable[[], Awaitable[bool]], timeout_s: float = _POLL_TIMEOUT_S
) -> bool:
    """Espera acotada (por defecto <=5s) a que `check()` sea verdadero."""
    deadline = asyncio.get_running_loop().time() + timeout_s
    while asyncio.get_running_loop().time() < deadline:
        if await check():
            return True
        await asyncio.sleep(_POLL_INTERVAL_S)
    return await check()


@pytest.fixture
def registry() -> EventRegistry:
    reg = EventRegistry()
    reg.register(TransactionCaptured)
    return reg


@pytest.fixture
async def redis_client(settings: Settings, redis_clean: None):
    del redis_clean
    client = redis_asyncio.from_url(str(settings.redis_url), decode_responses=False)
    try:
        yield client
    finally:
        await client.aclose()


def _bus(redis_client: redis_asyncio.Redis, registry: EventRegistry) -> RedisStreamsEventBus:
    return RedisStreamsEventBus(redis_client, registry, prefix=f"test:{uuid4()}")


async def test_publish_y_consumo_hace_ack_y_marca_procesado(
    redis_client, registry: EventRegistry
) -> None:
    bus = _bus(redis_client, registry)
    stream = bus.stream_name(_EVENT_TYPE)
    # Crear el grupo ANTES de publicar (XGROUP CREATE ... $): si el grupo se creara
    # despues del XADD (dentro del propio `run()` del consumer, en paralelo al
    # publish del test), el mensaje ya existente quedaria fuera de la ventana "$"
    # y jamas se entregaria. La propia llamada de `run()` a `ensure_group` es
    # entonces un no-op (BUSYGROUP).
    await bus.ensure_group(stream, "g1")
    event = _make_event()
    received: list[object] = []

    async def handler(event: object) -> None:
        received.append(event)

    consumer = StreamConsumer(
        bus,
        redis_client,
        registry,
        group="g1",
        event_type=_EVENT_TYPE,
        handler=handler,
        block_ms=200,
    )
    stop = asyncio.Event()
    task = asyncio.create_task(consumer.run(stop))
    try:
        await bus.publish(event)

        async def received_once() -> bool:
            return len(received) == 1

        assert await _poll_until(received_once)
    finally:
        stop.set()
        await task

    assert received == [event]
    pending = await redis_client.xpending(stream, "g1")
    assert pending["pending"] == 0
    processed_key = f"luka:events:processed:g1:{event.event_id}"
    assert await redis_client.exists(processed_key) == 1


async def test_mismo_event_id_no_reejecuta_pero_hace_ack(
    redis_client, registry: EventRegistry
) -> None:
    bus = _bus(redis_client, registry)
    stream = bus.stream_name(_EVENT_TYPE)
    await bus.ensure_group(stream, "g1")
    event = _make_event()
    calls: list[object] = []

    async def handler(event: object) -> None:
        calls.append(event)

    consumer = StreamConsumer(
        bus,
        redis_client,
        registry,
        group="g1",
        event_type=_EVENT_TYPE,
        handler=handler,
        block_ms=200,
    )
    stop = asyncio.Event()
    task = asyncio.create_task(consumer.run(stop))
    try:
        fields = registry.encode(event)
        await redis_client.xadd(stream, fields)

        async def called_once() -> bool:
            return len(calls) == 1

        assert await _poll_until(called_once)

        # Mismo event_id, entrada de stream distinta (redelivery a nivel de aplicacion).
        await redis_client.xadd(stream, fields)

        async def pending_back_to_zero() -> bool:
            summary = await redis_client.xpending(stream, "g1")
            return summary["pending"] == 0

        assert await _poll_until(pending_back_to_zero)
    finally:
        stop.set()
        await task

    assert len(calls) == 1  # el handler NO se re-ejecuto


async def test_handler_que_falla_termina_en_dlq_tras_max_deliveries(
    redis_client, registry: EventRegistry, monkeypatch: pytest.MonkeyPatch
) -> None:
    bus = _bus(redis_client, registry)
    stream = bus.stream_name(_EVENT_TYPE)
    await bus.ensure_group(stream, "g1")
    event = _make_event()
    attempts: list[object] = []
    # Espia del `XADD` a la DLQ: el recorte de la DLQ no se puede observar por
    # `XLEN` (MAXLEN ~ es aproximado y no recorta streams chicos), asi que se
    # verifica que el consumer pase el limite.
    dlq_xadd_kwargs: list[dict[str, object]] = []
    original_xadd = redis_client.xadd

    async def recording_xadd(name: str, fields: object, **kwargs: object) -> object:
        if name == bus.dlq_stream:
            dlq_xadd_kwargs.append(kwargs)
        return await original_xadd(name, fields, **kwargs)

    monkeypatch.setattr(redis_client, "xadd", recording_xadd)

    async def failing_handler(event: object) -> None:
        attempts.append(event)
        msg = "boom"
        raise RuntimeError(msg)

    consumer = StreamConsumer(
        bus,
        redis_client,
        registry,
        group="g1",
        event_type=_EVENT_TYPE,
        handler=failing_handler,
        block_ms=100,
        max_deliveries=2,
        claim_min_idle_ms=0,
    )
    stop = asyncio.Event()
    task = asyncio.create_task(consumer.run(stop))
    try:
        await bus.publish(event)

        async def dlq_has_entry() -> bool:
            return await redis_client.xlen(bus.dlq_stream) >= 1

        assert await _poll_until(dlq_has_entry)

        async def pending_back_to_zero() -> bool:
            summary = await redis_client.xpending(stream, "g1")
            return summary["pending"] == 0

        assert await _poll_until(pending_back_to_zero)
    finally:
        stop.set()
        await task

    dlq_entries = await redis_client.xrange(bus.dlq_stream)
    assert len(dlq_entries) == 1
    _dlq_id, dlq_fields = dlq_entries[0]
    assert dlq_xadd_kwargs == [{"maxlen": bus.maxlen, "approximate": True}]
    assert dlq_fields[b"failed_group"] == b"g1"
    assert dlq_fields[b"event_id"] == str(event.event_id).encode()
    # max_deliveries=2 cuenta INTENTOS de handler: se intenta 2 veces (delivery_count
    # 1 y 2, ninguno > max_deliveries) y recien en el 3er intento (delivery_count=3
    # > 2) se manda a DLQ sin volver a llamar al handler.
    assert len(attempts) == 2


async def test_error_transitorio_en_xack_no_mata_el_consumer(
    redis_client, registry: EventRegistry
) -> None:
    """Fix round 1 (review Task 14): antes, un `RedisError` en `XACK`/`XADD` DLQ
    dentro de `_process` (o en `ensure_group`, o en el propio `for` de `run()`)
    escapaba de `run()` sin proteccion y mataba la tarea de fondo para siempre.
    Ahora todo el cuerpo del loop es fail-soft: se loguea, se espera 1s y se
    reintenta; el mensaje no ackeado queda pendiente y se re-entrega.
    """
    bus = _bus(redis_client, registry)
    stream = bus.stream_name(_EVENT_TYPE)
    await bus.ensure_group(stream, "g1")
    event = _make_event()
    received: list[object] = []

    async def handler(event: object) -> None:
        received.append(event)

    consumer = StreamConsumer(
        bus,
        redis_client,
        registry,
        group="g1",
        event_type=_EVENT_TYPE,
        handler=handler,
        block_ms=200,
        claim_min_idle_ms=0,
    )

    original_xack = redis_client.xack
    xack_calls = {"n": 0}

    async def flaky_xack(*args: object, **kwargs: object) -> object:
        xack_calls["n"] += 1
        if xack_calls["n"] == 1:
            raise redis.exceptions.ConnectionError("boom")
        return await original_xack(*args, **kwargs)

    redis_client.xack = flaky_xack

    stop = asyncio.Event()
    task = asyncio.create_task(consumer.run(stop))
    try:
        await bus.publish(event)

        async def received_once() -> bool:
            return len(received) == 1

        assert await _poll_until(received_once)

        async def acked() -> bool:
            summary = await redis_client.xpending(stream, "g1")
            return summary["pending"] == 0

        assert await _poll_until(acked)
    finally:
        stop.set()
        await task
        redis_client.xack = original_xack

    assert xack_calls["n"] >= 2
    assert len(received) == 1  # el handler no se re-ejecuto: solo el ACK se reintento


async def test_ensure_group_falla_una_vez_y_el_consumer_arranca_igual(
    redis_client, registry: EventRegistry
) -> None:
    """Fix round 1 (review Task 14): `ensure_group` ahora se reintenta dentro del
    loop de `run()` en vez de correr una sola vez, sin proteccion, antes de el.
    """
    bus = _bus(redis_client, registry)
    stream = bus.stream_name(_EVENT_TYPE)
    # Se crea el grupo real ANTES de publicar (evita la carrera de otros tests) y
    # ANTES de parchear `ensure_group`: la version parchada solo simula una falla
    # transitoria en el primer llamado, delegando al original (que ya es un no-op
    # via BUSYGROUP) despues.
    await bus.ensure_group(stream, "g1")
    event = _make_event()
    received: list[object] = []

    async def handler(event: object) -> None:
        received.append(event)

    consumer = StreamConsumer(
        bus,
        redis_client,
        registry,
        group="g1",
        event_type=_EVENT_TYPE,
        handler=handler,
        block_ms=200,
    )

    original_ensure_group = bus.ensure_group
    ensure_group_calls = {"n": 0}

    async def flaky_ensure_group(stream: str, group: str) -> None:
        ensure_group_calls["n"] += 1
        if ensure_group_calls["n"] == 1:
            raise redis.exceptions.ConnectionError("boom")
        await original_ensure_group(stream, group)

    bus.ensure_group = flaky_ensure_group

    stop = asyncio.Event()
    task = asyncio.create_task(consumer.run(stop))
    try:
        await bus.publish(event)

        async def received_once() -> bool:
            return len(received) == 1

        assert await _poll_until(received_once)
    finally:
        stop.set()
        await task
        bus.ensure_group = original_ensure_group

    assert ensure_group_calls["n"] >= 2


async def test_dos_grupos_reciben_el_mismo_evento(redis_client, registry: EventRegistry) -> None:
    bus = _bus(redis_client, registry)
    stream = bus.stream_name(_EVENT_TYPE)
    # Se crean ambos grupos ANTES de publicar (XGROUP CREATE ... $): evita la carrera
    # de que un consumer arranque despues del publish y se pierda el mensaje.
    await bus.ensure_group(stream, "a")
    await bus.ensure_group(stream, "b")

    event = _make_event()
    received_a: list[object] = []
    received_b: list[object] = []

    async def handler_a(event: object) -> None:
        received_a.append(event)

    async def handler_b(event: object) -> None:
        received_b.append(event)

    consumer_a = StreamConsumer(
        bus,
        redis_client,
        registry,
        group="a",
        event_type=_EVENT_TYPE,
        handler=handler_a,
        block_ms=200,
    )
    consumer_b = StreamConsumer(
        bus,
        redis_client,
        registry,
        group="b",
        event_type=_EVENT_TYPE,
        handler=handler_b,
        block_ms=200,
    )
    stop_a, stop_b = asyncio.Event(), asyncio.Event()
    task_a = asyncio.create_task(consumer_a.run(stop_a))
    task_b = asyncio.create_task(consumer_b.run(stop_b))
    try:
        await bus.publish(event)

        async def both_received() -> bool:
            return len(received_a) == 1 and len(received_b) == 1

        assert await _poll_until(both_received)
    finally:
        stop_a.set()
        stop_b.set()
        await asyncio.gather(task_a, task_b)

    assert received_a == [event]
    assert received_b == [event]


@pytest.mark.parametrize("bus_kind", ["memory", "redis"])
async def test_publish_luego_handler_recibe_el_evento(
    bus_kind: str, redis_client, registry: EventRegistry
) -> None:
    """Contrato compartido: `InMemoryEventBus` y `RedisStreamsEventBus` entregan el
    mismo evento (por igualdad de valor, tras decodificar en el caso Redis) al
    handler suscrito/registrado.
    """
    event = _make_event()
    received: list[object] = []

    async def handler(event: object) -> None:
        received.append(event)

    if bus_kind == "memory":
        memory_bus = InMemoryEventBus(registry)
        memory_bus.subscribe(_EVENT_TYPE, handler)

        await memory_bus.publish(event)

        assert received == [event]
        assert memory_bus.published == [event]
        return

    redis_bus = _bus(redis_client, registry)
    await redis_bus.ensure_group(redis_bus.stream_name(_EVENT_TYPE), "contract")
    consumer = StreamConsumer(
        redis_bus,
        redis_client,
        registry,
        group="contract",
        event_type=_EVENT_TYPE,
        handler=handler,
        block_ms=200,
    )
    stop = asyncio.Event()
    task = asyncio.create_task(consumer.run(stop))
    try:
        await redis_bus.publish(event)

        async def received_once() -> bool:
            return len(received) == 1

        assert await _poll_until(received_once)
    finally:
        stop.set()
        await task

    assert received == [event]
