"""Integracion (spec 004 §3): tres amigos que envian $7.100 a la misma cuenta en
la misma ventana de 10 minutos son tres movimientos, no uno con tres fuentes.

- e2e: tres correos Bancolombia reales (anonimizados) -> pipeline -> 3 filas.
- reparacion: el estado del dedupe viejo (1 fila, 3 fuentes) ->
  `luka.tools.split_merged_captures.split` -> 3 filas, cada una con su fuente.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest
from sqlalchemy import text
from support.clock import FixedClock
from support.pipeline import InMemoryBudget, PipelineHarness, count_transactions

from luka.modules.ingestion.application.dto import RawMessageInput
from luka.modules.ingestion.domain.enums import Channel
from luka.modules.ingestion.public import Accepted, ingest_raw_message
from luka.modules.ledger import public as ledger_public
from luka.modules.ledger.domain.enums import Bank, Direction
from luka.modules.ledger.domain.enums import Channel as LedgerChannel
from luka.modules.parsing.infrastructure.llm.disabled import DisabledLlmParser
from luka.tools.split_merged_captures import parse_args, split

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable
    from uuid import UUID

    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
    from support.auth import AuthedUser

    from luka.shared.events.codec import EventRegistry
    from luka.shared.events.redis_streams import RedisStreamsEventBus
    from luka.shared.settings import Settings

pytestmark = pytest.mark.integration

_BOGOTA = timezone(timedelta(hours=-5))
_SENDER = "alertasynotificaciones@an.notificacionesbancolombia.com"
_FRIENDS = (
    ("MANUEL NIETO", "02:24"),
    ("TOMAS ALEJANDRO RODRIGUEZ COLMENARES", "02:26"),
    ("MARIANA GOMEZ ABRIL", "02:26"),
)


def _body(name: str, hhmm: str) -> str:
    return (
        "¡Listo!\nTodo salió bien con tus movimientos\n\n"
        f"Bancolombia: ANA, recibiste una transferencia de {name} por $7,100.00 en tu "
        f"cuenta *5533 conectada a la llave @ana6273 el 04/10/26 a las {hhmm}. Con llaves "
        "es de una y gratis. Dudas al 018000912345.\n"
    )


def _received_at(hhmm: str) -> datetime:
    hour, minute = (int(part) for part in hhmm.split(":"))
    return datetime(2026, 10, 4, hour, minute, 30, tzinfo=_BOGOTA)


async def _ingest(
    session_factory: async_sessionmaker[AsyncSession],
    bus: RedisStreamsEventBus,
    user_id: UUID,
    name: str,
    hhmm: str,
) -> UUID:
    received_at = _received_at(hhmm)
    async with session_factory() as session:
        outcome = await ingest_raw_message(
            session,
            bus,
            FixedClock(received_at),
            RawMessageInput(
                user_id=user_id,
                channel=Channel.EMAIL,
                external_id=f"gmail-{uuid4()}",
                sender=_SENDER,
                title=None,
                text=_body(name, hhmm),
                received_at=received_at,
            ),
        )
    assert isinstance(outcome, Accepted), outcome
    return outcome.raw_message_id


async def _merchants(session_factory: async_sessionmaker[AsyncSession], user_id: UUID):
    async with session_factory() as session:
        rows = await session.execute(
            text(
                "SELECT t.merchant, count(s.id) FROM transactions t "
                "JOIN transaction_sources s ON s.transaction_id = t.id "
                "WHERE t.user_id = :u GROUP BY t.id, t.merchant ORDER BY t.merchant"
            ),
            {"u": str(user_id)},
        )
        return [tuple(row) for row in rows]


_EXPECTED = [
    ("MANUEL NIETO", 1),
    ("MARIANA GOMEZ ABRIL", 1),
    ("TOMAS ALEJANDRO RODRIGUEZ COLMENARES", 1),
]


async def test_tres_correos_del_mismo_monto_son_tres_movimientos(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=FixedClock(_received_at("02:26")),
        llm=DisabledLlmParser(),
        budget=InMemoryBudget(),
        settings=settings,
    )
    try:
        for name, hhmm in _FRIENDS:
            await _ingest(session_factory, bus, user.id, name, hhmm)

        async def three() -> bool:
            return await count_transactions(session_factory, user.id) == 3

        assert await harness.wait_for(three)
    finally:
        await harness.stop()

    assert await _merchants(session_factory, user.id) == _EXPECTED


class _NullBus:
    """Descarta los eventos: aqui solo importa lo que queda en la base."""

    async def publish(self, event: object) -> None:
        del event


async def test_split_separa_un_movimiento_fusionado_por_el_dedupe_viejo(
    session_factory: async_sessionmaker[AsyncSession],
    bus: RedisStreamsEventBus,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_ids = [await _ingest(session_factory, bus, user.id, n, h) for n, h in _FRIENDS]
    first_at = _received_at("02:24").replace(second=0)
    async with session_factory() as session:
        recorded = await ledger_public.record_captured_transaction(
            session,
            _NullBus(),
            FixedClock(first_at),
            ledger_public.CapturedTransactionCommand(
                user_id=user.id,
                bank=Bank.BANCOLOMBIA,
                amount=Decimal("7100"),
                direction=Direction.CREDIT,
                occurred_at=first_at,
                last4="5533",
                merchant="MANUEL NIETO",
                description=None,
                suggested_category_slug=None,
                parsed_by="rule:bancolombia:transferencia_llave_recibida:v1",
                confidence=None,
                source=ledger_public.SourceInput(LedgerChannel.EMAIL, raw_ids[0], first_at),
                merchant_is_person=True,
            ),
        )
        # Estado del dedupe viejo: las otras dos fuentes, pegadas a la primera.
        for raw_id in raw_ids[1:]:
            await session.execute(
                text(
                    "INSERT INTO transaction_sources "
                    "(id, transaction_id, raw_message_id, channel, received_at) "
                    "VALUES (:id, :t, :r, 'email', :at)"
                ),
                {
                    "id": str(uuid4()),
                    "t": str(recorded.transaction.id),
                    "r": str(raw_id),
                    "at": first_at,
                },
            )
        await session.commit()
    assert await count_transactions(session_factory, user.id) == 1

    async with session_factory() as session:
        summary = await split(session, _NullBus(), FixedClock(first_at), user_id=user.id)
    async with session_factory() as session:
        again = await split(session, _NullBus(), FixedClock(first_at), user_id=user.id)

    assert summary.split == 2
    assert summary.unreadable == 0
    assert again.split == 0
    assert await _merchants(session_factory, user.id) == _EXPECTED


def test_parse_args_user_opcional() -> None:
    assert parse_args([]).user is None
    user = uuid4()
    assert parse_args(["--user", str(user)]).user == user
