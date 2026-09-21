"""Tests de integracion del job de purga de cuerpos (`purge_raw_message_bodies`,
spec 004 §6, RF-11 AC-11.4, Constitucion P6, F3.7 adelantado en F2 - Task 10).

Ejercita `ingestion.public.purge_expired_bodies` (lo que llama el cron del worker)
contra Postgres real: filas vencidas vs. vigentes, idempotencia, y que un item ya
purgado se siga listando en `/v1/review` con `text: null` (la app muestra
"contenido expirado").
"""

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.raw_messages import insert_raw_message

from finanzia.modules.ingestion import public
from finanzia.modules.ledger.infrastructure.consumers import make_parse_failed_handler
from finanzia.modules.parsing.domain.enums import ParseFailureReason
from finanzia.modules.parsing.events import ParseFailed
from finanzia.shared.clock import SystemClock

pytestmark = pytest.mark.integration

_NOW = datetime(2026, 5, 1, 12, 0, tzinfo=UTC)


async def test_purge_job_anula_body_de_filas_vencidas_y_respeta_las_vigentes(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    vencido_1 = await insert_raw_message(
        session_factory,
        user_id=user.id,
        external_id="purge-job-1",
        received_at=_NOW - timedelta(days=200),
    )
    vencido_2 = await insert_raw_message(
        session_factory,
        user_id=user.id,
        external_id="purge-job-2",
        received_at=_NOW - timedelta(days=150),
    )
    vigente = await insert_raw_message(
        session_factory, user_id=user.id, external_id="purge-job-3", received_at=_NOW
    )

    async with session_factory() as session:
        count = await public.purge_expired_bodies(session, _NOW)
    assert count == 2

    async with session_factory() as session:
        rows = (
            await session.execute(
                text("SELECT id, body, status FROM raw_messages WHERE id = ANY(:ids)"),
                {"ids": [vencido_1, vencido_2, vigente]},
            )
        ).mappings()
        by_id = {row["id"]: row for row in rows}

    assert by_id[vencido_1]["body"] is None
    assert by_id[vencido_1]["status"] == "pending"  # el purge no toca status
    assert by_id[vencido_2]["body"] is None
    assert by_id[vencido_2]["status"] == "pending"
    assert by_id[vigente]["body"] is not None

    # Idempotente: una segunda corrida no vuelve a contar filas ya purgadas.
    async with session_factory() as session:
        second_count = await public.purge_expired_bodies(session, _NOW)
    assert second_count == 0


async def test_get_review_de_item_encolado_y_luego_purgado_devuelve_text_null(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(
        session_factory,
        user_id=user.id,
        external_id="purge-job-review",
        received_at=_NOW - timedelta(days=200),
    )

    handler = make_parse_failed_handler(session_factory=session_factory, clock=SystemClock())
    await handler(
        ParseFailed(
            event_id=uuid4(),
            occurred_at=datetime.now(UTC),
            raw_message_id=raw_message_id,
            user_id=user.id,
            channel="email",
            bank="bancolombia",
            reason=ParseFailureReason.LLM_LOW_CONFIDENCE,
            partial_extract={},
            received_at=_NOW - timedelta(days=200),
        )
    )

    async with session_factory() as session:
        count = await public.purge_expired_bodies(session, _NOW)
    assert count == 1

    response = await client.get("/v1/review", headers=user.headers)
    assert response.status_code == 200, response.text
    items = response.json()["items"]
    assert len(items) == 1
    assert items[0]["raw_message_id"] == str(raw_message_id)
    assert items[0]["text"] is None
