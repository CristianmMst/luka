"""Harness de tests: arranca los 3 `StreamConsumer` del pipeline de captura
(parsing + ledger) sobre Redis/DB reales, igual que `finanzia.worker` pero con
timings cortos para tests (spec 003 SS2.3-2.4, F2.2/F2.5/F2.6, Task 9).

Deliberadamente NO arranca el `ledger-observer` (`ledger.TransactionCaptured`):
ningun test e2e del pipeline necesita ese logger, solo los 3 consumers que
mueven un `raw_message` hasta convertirse en transaccion o en revision.
"""

from __future__ import annotations

import asyncio
from typing import TYPE_CHECKING
from uuid import uuid4

from sqlalchemy import text

from finanzia.modules.ledger.infrastructure.consumers import (
    make_parse_failed_handler,
    make_transaction_parsed_handler,
)
from finanzia.modules.parsing.infrastructure.config_loader import load_parsing_config
from finanzia.modules.parsing.infrastructure.consumers import make_raw_message_received_handler
from finanzia.modules.parsing.infrastructure.metrics import StructlogMetrics
from finanzia.shared.events.consumer import StreamConsumer

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable
    from datetime import date
    from uuid import UUID

    import redis.asyncio as redis_asyncio
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

    from finanzia.modules.parsing.application.dto import LlmResult
    from finanzia.modules.parsing.application.ports import (
        ClockPort,
        LlmBudgetPort,
        LlmParserPort,
    )
    from finanzia.shared.events.codec import EventRegistry
    from finanzia.shared.events.redis_streams import RedisStreamsEventBus
    from finanzia.shared.settings import Settings

_BLOCK_MS = 200
_CLAIM_MIN_IDLE_MS = 0
_MAX_DELIVERIES = 5
_DEFAULT_WAIT_TIMEOUT_S = 8.0
_DEFAULT_WAIT_INTERVAL_S = 0.1

# Los 3 grupos que mueven un `raw_message` hasta transaccion/revision (excluye
# `ledger-observer`, ver docstring del modulo). Mismos `(event_type, group)` que
# `events_registry.CONSUMER_GROUPS`.
_WIRED_GROUPS: tuple[tuple[str, str], ...] = (
    ("ingestion.RawMessageReceived", "parsing"),
    ("parsing.TransactionParsed", "ledger"),
    ("parsing.ParseFailed", "ledger-review"),
)


class PipelineHarness:
    """Arranca/detiene los 3 `StreamConsumer` del pipeline de captura en tests."""

    def __init__(self) -> None:
        self._stop = asyncio.Event()
        self._tasks: list[asyncio.Task[None]] = []

    async def start(  # noqa: PLR0913 - un parametro por dependencia externa (igual que worker.py)
        self,
        *,
        session_factory: async_sessionmaker[AsyncSession],
        redis: redis_asyncio.Redis,
        registry: EventRegistry,
        bus: RedisStreamsEventBus,
        clock: ClockPort,
        llm: LlmParserPort,
        budget: LlmBudgetPort,
        settings: Settings,
    ) -> None:
        """Cablea los 3 handlers (misma fabrica que `finanzia.worker`) y arranca
        sus `StreamConsumer` bajo `asyncio.create_task`, con `ensure_group` antes
        de cualquier publish del test (evita perder el primer evento por la
        ventana `$` de `XGROUP CREATE`).
        """
        parsing_handler = make_raw_message_received_handler(
            session_factory=session_factory,
            event_bus=bus,
            clock=clock,
            llm=llm,
            budget=budget,
            registry=load_parsing_config().templates,
            metrics=StructlogMetrics(),
            settings=settings,
        )
        ledger_transaction_handler = make_transaction_parsed_handler(
            session_factory=session_factory, event_bus=bus, clock=clock
        )
        ledger_review_handler = make_parse_failed_handler(
            session_factory=session_factory, clock=clock
        )
        handlers = {
            "ingestion.RawMessageReceived": parsing_handler,
            "parsing.TransactionParsed": ledger_transaction_handler,
            "parsing.ParseFailed": ledger_review_handler,
        }

        for event_type, group in _WIRED_GROUPS:
            stream = bus.stream_name(event_type)
            await bus.ensure_group(stream, group)
            consumer = StreamConsumer(
                bus,
                redis,
                registry,
                group=group,
                event_type=event_type,
                handler=handlers[event_type],
                consumer_name=f"harness-{event_type}-{uuid4()}",
                block_ms=_BLOCK_MS,
                claim_min_idle_ms=_CLAIM_MIN_IDLE_MS,
                max_deliveries=_MAX_DELIVERIES,
            )
            self._tasks.append(asyncio.create_task(consumer.run(self._stop)))

    async def stop(self) -> None:
        """Detiene los 3 consumers y espera a que sus tareas terminen (sin tareas colgadas)."""
        self._stop.set()
        if self._tasks:
            await asyncio.gather(*self._tasks, return_exceptions=True)
            self._tasks = []

    async def wait_for(
        self,
        predicate: Callable[[], Awaitable[bool]],
        *,
        timeout: float = _DEFAULT_WAIT_TIMEOUT_S,  # noqa: ASYNC109 - firma pedida por el brief
        interval: float = _DEFAULT_WAIT_INTERVAL_S,
    ) -> bool:
        """Espera acotada (por defecto <=8s) a que `predicate()` sea verdadero."""
        deadline = asyncio.get_running_loop().time() + timeout
        while asyncio.get_running_loop().time() < deadline:
            if await predicate():
                return True
            await asyncio.sleep(interval)
        return await predicate()


# --- Helpers de aserciones sobre DB/Redis (fuera de la clase: no dependen de ---
# --- ningun estado del harness, solo de `session_factory`/`redis`) -----------


async def count_transactions(
    session_factory: async_sessionmaker[AsyncSession], user_id: UUID
) -> int:
    """Cuantas filas de `transactions` tiene `user_id`."""
    async with session_factory() as session:
        return (
            await session.execute(
                text("SELECT count(*) FROM transactions WHERE user_id = :u"), {"u": str(user_id)}
            )
        ).scalar_one()


async def count_sources(
    session_factory: async_sessionmaker[AsyncSession], transaction_id: UUID
) -> int:
    """Cuantas filas de `transaction_sources` tiene `transaction_id`."""
    async with session_factory() as session:
        return (
            await session.execute(
                text("SELECT count(*) FROM transaction_sources WHERE transaction_id = :t"),
                {"t": str(transaction_id)},
            )
        ).scalar_one()


async def raw_status(
    session_factory: async_sessionmaker[AsyncSession], raw_message_id: UUID
) -> str | None:
    """`status` de la fila `raw_messages` (`None` si no existe)."""
    async with session_factory() as session:
        row = (
            await session.execute(
                text("SELECT status FROM raw_messages WHERE id = :i"), {"i": str(raw_message_id)}
            )
        ).one_or_none()
    return row.status if row is not None else None


async def review_reason(
    session_factory: async_sessionmaker[AsyncSession], raw_message_id: UUID
) -> str | None:
    """`reason` de la fila abierta de `review_queue` para `raw_message_id` (`None` si no hay)."""
    async with session_factory() as session:
        row = (
            await session.execute(
                text(
                    "SELECT reason FROM review_queue "
                    "WHERE raw_message_id = :i AND resolved_at IS NULL"
                ),
                {"i": str(raw_message_id)},
            )
        ).one_or_none()
    return row.reason if row is not None else None


async def stream_len(redis: redis_asyncio.Redis, stream: str) -> int:
    """Longitud del stream (para depurar/asertar reentregas manuales via `XADD`)."""
    return await redis.xlen(stream)


async def fetch_transaction(session_factory: async_sessionmaker[AsyncSession], user_id: UUID):
    """La (unica) transaccion de `user_id`, con su categoria, para los asserts e2e.

    No forma parte de la lista de helpers del brief pero es necesaria: los tests
    e2e verifican mas campos que un conteo (`amount`, `direction`, `merchant`,
    `occurred_at`, `bank`, `parsed_by`, `confidence`, `account_id`, `category_slug`).
    """
    async with session_factory() as session:
        return (
            await session.execute(
                text(
                    "SELECT t.id, t.amount, t.direction, t.merchant, t.occurred_at, t.bank, "
                    "t.parsed_by, t.confidence, t.account_id, c.slug AS category_slug "
                    "FROM transactions t JOIN categories c ON c.id = t.category_id "
                    "WHERE t.user_id = :u"
                ),
                {"u": str(user_id)},
            )
        ).one()


class FakeLlmParser:
    """Doble minimo de `LlmParserPort` para los tests e2e del pipeline.

    Reproduce un guion de resultados/excepciones (uno por llamada a `parse`),
    igual que `tests/unit/parsing/fakes.FakeLlmParser`; se duplica aqui (en vez
    de importar ese modulo) porque `tests/integration/pipeline` no comparte
    `sys.path` con `tests/unit` cuando se corre en aislamiento (p. ej.
    `pytest tests/integration/pipeline`, la verificacion del Task 9).
    """

    def __init__(self, script: list[LlmResult | Exception], *, enabled: bool = True) -> None:
        self._script = list(script)
        self.enabled = enabled
        self.calls: list[tuple[str, date]] = []

    async def parse(self, excerpt: str, received_on: date) -> LlmResult:
        self.calls.append((excerpt, received_on))
        item = self._script.pop(0)
        if isinstance(item, Exception):
            raise item
        return item


class InMemoryBudget:
    """Doble minimo de `LlmBudgetPort`: tokens usados por `(user_id, month_key)`.

    Ver el docstring de `FakeLlmParser` sobre por que se duplica en vez de
    importar `tests/unit/parsing/fakes.InMemoryBudget`.
    """

    def __init__(self, initial: dict[tuple[UUID, str], int] | None = None) -> None:
        self._used: dict[tuple[UUID, str], int] = dict(initial or {})
        self.adds: list[tuple[UUID, str, int]] = []

    async def used(self, user_id: UUID, month_key: str) -> int:
        return self._used.get((user_id, month_key), 0)

    async def add(self, user_id: UUID, month_key: str, tokens: int) -> None:
        self.adds.append((user_id, month_key, tokens))
        key = (user_id, month_key)
        self._used[key] = self._used.get(key, 0) + tokens


__all__ = [
    "FakeLlmParser",
    "InMemoryBudget",
    "PipelineHarness",
    "count_sources",
    "count_transactions",
    "fetch_transaction",
    "raw_status",
    "review_reason",
    "stream_len",
]
