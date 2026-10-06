"""CLI: separa capturas entre personas fusionadas por el dedupe viejo (spec 004 §3).

    uv run python -m luka.tools.split_merged_captures [--user UUID]

Antes la huella de dedupe no miraba la contraparte: tres amigos que te envian
$7.100 en la misma ventana de 10 minutos quedaban como un solo movimiento con tres
fuentes. Este comando re-parsea cada fuente (solo plantillas, sin LLM) y registra
como movimiento propio la de cada contraparte distinta; correo y notificacion del
mismo envio siguen juntos. Los movimientos nuevos se publican en el bus como
cualquier captura. Idempotente: correrlo de nuevo no separa nada mas.

Solo imprime conteos: nunca ids, montos ni nombres (P1).
"""

from __future__ import annotations

import argparse
import asyncio
import sys
from typing import TYPE_CHECKING
from uuid import UUID

import redis.asyncio as redis_asyncio

from luka.events_registry import build_registry, ensure_consumer_groups
from luka.modules.ingestion import public as ingestion_public
from luka.modules.ledger import public as ledger_public
from luka.modules.ledger.infrastructure.consumers import capture_command_from_parsed
from luka.modules.parsing import public as parsing_public
from luka.shared.clock import SystemClock
from luka.shared.db.engine import create_engine, create_session_factory
from luka.shared.events.redis_streams import RedisStreamsEventBus
from luka.shared.logging import configure_logging
from luka.shared.settings import get_settings
from luka.worker import (
    CONSUMER_GROUPS_TIMEOUT_S,
    REDIS_CONNECT_TIMEOUT_S,
    REDIS_SOCKET_TIMEOUT_S,
)

if TYPE_CHECKING:
    from collections.abc import Sequence

    from sqlalchemy.ext.asyncio import AsyncSession

    from luka.modules.ledger.application.dto import CapturedTransactionCommand
    from luka.modules.ledger.application.ports import ClockPort
    from luka.shared.events.port import EventBusPort
    from luka.shared.settings import Settings


class TemplateCaptureReader:
    """`CaptureReaderPort`: lee el `raw_message` (ingestion) y lo re-parsea con
    las plantillas (parsing). `None` si el cuerpo ya se purgo o no matchea."""

    def __init__(self, session: AsyncSession, clock: ClockPort) -> None:
        self._session = session
        self._clock = clock

    async def capture_for(self, raw_message_id: UUID) -> CapturedTransactionCommand | None:
        view = await ingestion_public.get_raw_message_for_parsing(self._session, raw_message_id)
        if view is None or view.body is None:
            return None
        parsed = parsing_public.parse_with_templates(
            raw_message_id=view.id,
            user_id=view.user_id,
            channel=view.channel.value,
            bank=view.bank,
            body=view.body,
            received_at=view.received_at,
            now=self._clock.now(),
        )
        return capture_command_from_parsed(parsed) if parsed is not None else None


async def split(
    session: AsyncSession, bus: EventBusPort, clock: ClockPort, *, user_id: UUID | None
) -> ledger_public.SplitMergedCapturesSummary:
    """Arma el lector y corre el caso de uso de ledger sobre `session`."""
    return await ledger_public.split_merged_captures(
        session,
        bus,
        clock,
        reader=TemplateCaptureReader(session, clock),
        person_parsed_by=parsing_public.person_transfer_parsed_by(),
        user_id=user_id,
    )


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="python -m luka.tools.split_merged_captures",
        description="Separa los envios y recibos entre personas fusionados por el dedupe.",
    )
    parser.add_argument("--user", type=UUID, default=None, help="solo este usuario (id)")
    return parser.parse_args(argv)


async def run(
    settings: Settings, *, user_id: UUID | None
) -> ledger_public.SplitMergedCapturesSummary:
    """Arma engine, Redis y bus como el worker, separa y los libera."""
    engine = create_engine(settings)
    redis_client = redis_asyncio.from_url(
        str(settings.redis_url),
        decode_responses=False,
        socket_connect_timeout=REDIS_CONNECT_TIMEOUT_S,
        socket_timeout=REDIS_SOCKET_TIMEOUT_S,
    )
    bus = RedisStreamsEventBus(redis_client, build_registry())
    try:
        await asyncio.wait_for(ensure_consumer_groups(bus), timeout=CONSUMER_GROUPS_TIMEOUT_S)
        async with create_session_factory(engine)() as session:
            return await split(session, bus, SystemClock(), user_id=user_id)
    finally:
        await redis_client.aclose()
        await engine.dispose()


def main(argv: Sequence[str] | None = None) -> int:
    """Punto de entrada; imprime `split=<n> unreadable=<m>`."""
    args = parse_args(argv)
    settings = get_settings()
    configure_logging(settings)
    summary = asyncio.run(run(settings, user_id=args.user))
    sys.stdout.write(f"split={summary.split} unreadable={summary.unreadable}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
