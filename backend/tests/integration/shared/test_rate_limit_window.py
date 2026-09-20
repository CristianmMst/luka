"""Tests de `SlidingWindowLimiter` contra Redis real (spec 009 SS4, F1.4).

Requiere infraestructura real (Redis), por eso vive en `tests/integration` con
marker `integration` aunque ejercite una sola clase (sin la app HTTP completa).
"""

import uuid
from collections.abc import AsyncGenerator

import pytest
import redis.asyncio as redis_asyncio
from redis.asyncio import Redis

from finanzia.shared.http.rate_limit import SlidingWindowLimiter
from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration


class _MutableClock:
    """Reloj controlable por el test: implementa `Callable[[], float]` + `advance`."""

    def __init__(self, start: float) -> None:
        self._now = start

    def __call__(self) -> float:
        return self._now

    def advance(self, seconds: float) -> None:
        self._now += seconds


@pytest.fixture
async def redis_client(settings: Settings) -> AsyncGenerator[Redis, None]:
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        yield client
    finally:
        await client.aclose()


async def test_permite_hasta_el_limite_y_rechaza_el_siguiente(redis_client: Redis) -> None:
    key = f"test:rl:{uuid.uuid4()}"
    clock = _MutableClock(1_000_000.0)
    limiter = SlidingWindowLimiter(redis_client, now=clock)
    try:
        for _ in range(10):
            decision = await limiter.hit(key, limit=10, window_s=60)
            assert decision.allowed
            assert decision.retry_after == 0

        rejected = await limiter.hit(key, limit=10, window_s=60)
        assert not rejected.allowed
        assert rejected.retry_after == 60
    finally:
        await redis_client.delete(key)


async def test_permite_de_nuevo_tras_avanzar_la_ventana_completa(redis_client: Redis) -> None:
    key = f"test:rl:{uuid.uuid4()}"
    clock = _MutableClock(1_000_000.0)
    limiter = SlidingWindowLimiter(redis_client, now=clock)
    try:
        for _ in range(10):
            assert (await limiter.hit(key, limit=10, window_s=60)).allowed
        assert not (await limiter.hit(key, limit=10, window_s=60)).allowed

        clock.advance(60.0)

        decision = await limiter.hit(key, limit=10, window_s=60)
        assert decision.allowed
    finally:
        await redis_client.delete(key)


async def test_claves_distintas_son_independientes(redis_client: Redis) -> None:
    key_a = f"test:rl:{uuid.uuid4()}"
    key_b = f"test:rl:{uuid.uuid4()}"
    clock = _MutableClock(1_000_000.0)
    limiter = SlidingWindowLimiter(redis_client, now=clock)
    try:
        for _ in range(10):
            assert (await limiter.hit(key_a, limit=10, window_s=60)).allowed

        assert not (await limiter.hit(key_a, limit=10, window_s=60)).allowed
        assert (await limiter.hit(key_b, limit=10, window_s=60)).allowed
    finally:
        await redis_client.delete(key_a)
        await redis_client.delete(key_b)


async def test_retry_after_disminuye_a_medida_que_avanza_el_tiempo(redis_client: Redis) -> None:
    key = f"test:rl:{uuid.uuid4()}"
    clock = _MutableClock(1_000_000.0)
    limiter = SlidingWindowLimiter(redis_client, now=clock)
    try:
        for _ in range(10):
            assert (await limiter.hit(key, limit=10, window_s=60)).allowed

        rejected_at_zero = await limiter.hit(key, limit=10, window_s=60)
        assert rejected_at_zero.retry_after == 60

        clock.advance(30.0)

        rejected_at_30 = await limiter.hit(key, limit=10, window_s=60)
        assert rejected_at_30.retry_after == 30
    finally:
        await redis_client.delete(key)
