"""CLI: reclasifica transferencias propias ya capturadas (spec 004 §4.1).

    uv run python -m finanzia.tools.mark_self_transfers [--user UUID]

Las capturas entre personas (plantillas con `counterparty: true`) cuya
contraparte es el titular pasan a `transfer`, como las nuevas. Las filas que
el usuario edito despues de capturarlas no se tocan y se cuentan aparte.
Idempotente: correrlo de nuevo no marca nada mas. No necesita el worker.

Solo imprime conteos: nunca ids, montos ni nombres (P1).
"""

from __future__ import annotations

import argparse
import asyncio
import sys
from typing import TYPE_CHECKING
from uuid import UUID

from finanzia.modules.ledger import public as ledger_public
from finanzia.modules.parsing import public as parsing_public
from finanzia.shared.clock import SystemClock
from finanzia.shared.db.engine import create_engine, create_session_factory
from finanzia.shared.logging import configure_logging
from finanzia.shared.settings import get_settings

if TYPE_CHECKING:
    from collections.abc import Sequence

    from finanzia.shared.settings import Settings


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="python -m finanzia.tools.mark_self_transfers",
        description="Marca como transferencia los envios y recibos al propio titular.",
    )
    parser.add_argument("--user", type=UUID, default=None, help="solo este usuario (id)")
    return parser.parse_args(argv)


async def run(
    settings: Settings, *, user_id: UUID | None
) -> ledger_public.MarkSelfTransfersSummary:
    engine = create_engine(settings)
    try:
        async with create_session_factory(engine)() as session:
            return await ledger_public.mark_self_transfers(
                session,
                SystemClock(),
                person_parsed_by=parsing_public.person_transfer_parsed_by(),
                user_id=user_id,
            )
    finally:
        await engine.dispose()


def main(argv: Sequence[str] | None = None) -> int:
    """Punto de entrada; imprime `marked=<n> skipped_edited=<m>`."""
    args = parse_args(argv)
    settings = get_settings()
    configure_logging(settings)
    summary = asyncio.run(run(settings, user_id=args.user))
    sys.stdout.write(f"marked={summary.marked} skipped_edited={summary.skipped_edited}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
