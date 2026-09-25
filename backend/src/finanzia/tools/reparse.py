"""CLI: reprocesa los `raw_messages` `failed` con cuerpo (spec 005 §7, spec 006 §4.4).

    uv run python -m finanzia.tools.reparse [--since AAAA-MM-DD] [--user UUID] [--limit N]

Composition root de un solo uso: arma engine, Redis y bus igual que
`finanzia.worker.on_startup` (mismos settings, mismos timeouts, mismos grupos de
consumidores) y llama a `ingestion.public.reparse_failed_raw_messages`. El worker
en marcha consume los `RawMessageReceived` republicados; si ahora parsean, ledger
cierra su item de revision como `reparsed`.

`--since` es una fecha de Colombia (medianoche America/Bogota, UTC-5 fijo) sobre
`received_at`. Toma hasta `--limit` filas por corrida; correrlo de nuevo sigue con
las que falten y nunca repite una ya reencolada (dejo de estar `failed`).

Solo imprime conteos: nunca ids, montos, remitentes ni cuerpos (P1).
"""

from __future__ import annotations

import argparse
import asyncio
import sys
from datetime import date, datetime, time, timedelta, timezone
from typing import TYPE_CHECKING
from uuid import UUID

import redis.asyncio as redis_asyncio

from finanzia.events_registry import build_registry, ensure_consumer_groups
from finanzia.modules.ingestion import public as ingestion_public
from finanzia.shared.clock import SystemClock
from finanzia.shared.db.engine import create_engine, create_session_factory
from finanzia.shared.events.redis_streams import RedisStreamsEventBus
from finanzia.shared.logging import configure_logging
from finanzia.shared.settings import get_settings

if TYPE_CHECKING:
    from collections.abc import Sequence

    from finanzia.shared.settings import Settings

_BOGOTA = timezone(timedelta(hours=-5))
_LIMIT_DEFAULT = 500
# Mismos valores que `finanzia.worker` (ver alli el por que de cada uno).
_REDIS_CONNECT_TIMEOUT_S = 2.0
_REDIS_SOCKET_TIMEOUT_S = 10.0


def since_to_datetime(day: date) -> datetime:
    """Medianoche de `day` en Colombia (UTC-5 fijo, sin horario de verano)."""
    return datetime.combine(day, time.min, tzinfo=_BOGOTA)


def _positive_int(value: str) -> int:
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError("debe ser >= 1")
    return number


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    """Argumentos del CLI; un valor invalido termina con codigo 2 (argparse)."""
    parser = argparse.ArgumentParser(
        prog="python -m finanzia.tools.reparse",
        description="Reprocesa los mensajes crudos fallidos (con cuerpo) y cierra su revision.",
    )
    parser.add_argument(
        "--since",
        type=date.fromisoformat,
        default=None,
        help="solo mensajes recibidos desde esta fecha (AAAA-MM-DD, hora de Colombia)",
    )
    parser.add_argument("--user", type=UUID, default=None, help="solo este usuario (id)")
    parser.add_argument(
        "--limit", type=_positive_int, default=_LIMIT_DEFAULT, help="maximo de filas por corrida"
    )
    return parser.parse_args(argv)


async def run(
    settings: Settings, *, since: date | None, user_id: UUID | None, limit: int
) -> ingestion_public.ReparseSummary:
    """Arma la composicion del worker, reencola y libera engine y Redis."""
    engine = create_engine(settings)
    session_factory = create_session_factory(engine)
    redis_client = redis_asyncio.from_url(
        str(settings.redis_url),
        decode_responses=False,
        socket_connect_timeout=_REDIS_CONNECT_TIMEOUT_S,
        socket_timeout=_REDIS_SOCKET_TIMEOUT_S,
    )
    bus = RedisStreamsEventBus(redis_client, build_registry())
    try:
        # Sin el grupo `parsing`, un stream nuevo perderia los eventos (D10).
        await ensure_consumer_groups(bus)
        async with session_factory() as session:
            return await ingestion_public.reparse_failed_raw_messages(
                session,
                bus,
                SystemClock(),
                user_id=user_id,
                since=since_to_datetime(since) if since is not None else None,
                limit=limit,
            )
    finally:
        await redis_client.aclose()
        await engine.dispose()


def main(argv: Sequence[str] | None = None) -> int:
    """Punto de entrada; imprime `reparsed=<n>`."""
    args = parse_args(argv)
    settings = get_settings()
    configure_logging(settings)
    summary = asyncio.run(run(settings, since=args.since, user_id=args.user, limit=args.limit))
    sys.stdout.write(f"reparsed={summary.reparsed}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
