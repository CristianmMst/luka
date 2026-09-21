"""Tests de integracion de `RedisLlmBudget` (spec 006 §4.2), sobre Redis real."""

from __future__ import annotations

from uuid import uuid4

import pytest
import redis.asyncio as redis_asyncio

from finanzia.modules.parsing.infrastructure.llm.budget_redis import RedisLlmBudget
from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration

_MONTH_KEY = "202609"


@pytest.fixture
async def redis_client(settings: Settings):
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        yield client
    finally:
        await client.aclose()


async def test_used_es_cero_cuando_no_hay_clave(redis_client: redis_asyncio.Redis) -> None:
    budget = RedisLlmBudget(redis_client)
    user_id = uuid4()

    assert await budget.used(user_id, _MONTH_KEY) == 0


async def test_add_incrementa_y_used_lo_refleja(redis_client: redis_asyncio.Redis) -> None:
    budget = RedisLlmBudget(redis_client)
    user_id = uuid4()

    await budget.add(user_id, _MONTH_KEY, 1200)

    assert await budget.used(user_id, _MONTH_KEY) == 1200


async def test_varios_add_se_acumulan(redis_client: redis_asyncio.Redis) -> None:
    budget = RedisLlmBudget(redis_client)
    user_id = uuid4()

    await budget.add(user_id, _MONTH_KEY, 500)
    await budget.add(user_id, _MONTH_KEY, 700)

    assert await budget.used(user_id, _MONTH_KEY) == 1200


async def test_add_fija_ttl_entre_30_y_40_dias(redis_client: redis_asyncio.Redis) -> None:
    budget = RedisLlmBudget(redis_client)
    user_id = uuid4()
    key = f"llm:budget:{user_id}:{_MONTH_KEY}"

    await budget.add(user_id, _MONTH_KEY, 1200)

    ttl = await redis_client.ttl(key)
    assert 30 * 24 * 3600 <= ttl <= 40 * 24 * 3600


async def test_add_no_extiende_el_ttl_si_ya_existia(redis_client: redis_asyncio.Redis) -> None:
    """`EXPIRE ... NX`: un segundo `add` en el mismo mes no reinicia la ventana."""
    budget = RedisLlmBudget(redis_client)
    user_id = uuid4()
    key = f"llm:budget:{user_id}:{_MONTH_KEY}"

    await budget.add(user_id, _MONTH_KEY, 100)
    ttl_after_first = await redis_client.ttl(key)

    await redis_client.expire(key, 1000)
    await budget.add(user_id, _MONTH_KEY, 100)
    ttl_after_second = await redis_client.ttl(key)

    assert ttl_after_first > 1000
    assert ttl_after_second <= 1000


async def test_usuarios_y_meses_distintos_no_se_mezclan(redis_client: redis_asyncio.Redis) -> None:
    budget = RedisLlmBudget(redis_client)
    user_a, user_b = uuid4(), uuid4()

    await budget.add(user_a, _MONTH_KEY, 1000)
    await budget.add(user_b, _MONTH_KEY, 5)
    await budget.add(user_a, "202608", 999)

    assert await budget.used(user_a, _MONTH_KEY) == 1000
    assert await budget.used(user_b, _MONTH_KEY) == 5
    assert await budget.used(user_a, "202608") == 999
