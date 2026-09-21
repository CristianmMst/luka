"""Fixtures compartidas de los tests e2e del pipeline (parsing + ledger, Task 9).

`redis_clean`/`db_clean` autouse: cada test arranca con la Redis de test (db 1) y
las tablas de usuario vacias, para no interferir entre streams/consumer groups de
distintos tests (todos publican sobre el mismo prefijo real `finanzia:events`,
D7/D10). `redis_client`/`registry`/`bus` son los mismos objetos que arma
`finanzia.worker` (composition root), reutilizables por cualquier test del paquete.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import pytest
import redis.asyncio as redis_asyncio

from finanzia.events_registry import build_registry
from finanzia.shared.events.redis_streams import RedisStreamsEventBus

if TYPE_CHECKING:
    from finanzia.shared.events.codec import EventRegistry
    from finanzia.shared.settings import Settings


@pytest.fixture(autouse=True)
async def _pipeline_clean(redis_clean: None, db_clean: None) -> None:
    del redis_clean, db_clean


@pytest.fixture
async def redis_client(settings: Settings):
    client = redis_asyncio.from_url(str(settings.redis_url), decode_responses=False)
    try:
        yield client
    finally:
        await client.aclose()


@pytest.fixture
def registry() -> EventRegistry:
    return build_registry()


@pytest.fixture
def bus(redis_client: redis_asyncio.Redis, registry: EventRegistry) -> RedisStreamsEventBus:
    return RedisStreamsEventBus(redis_client, registry)
