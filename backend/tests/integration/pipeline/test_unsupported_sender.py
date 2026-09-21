"""Test e2e de AC-2.4 (spec 006 SS2.2): un remitente fuera de la lista blanca se
descarta en la ingesta sin persistir nada ni loguear el cuerpo/remitente (P1/P6).

El fixture de Nu (`tests/fixtures/emails/other/nu_pago.txt`) menciona
"CORREDORES DAVIVIENDA S A COMISIONISTA DE BOLSA" en su asunto/cuerpo a
proposito (ver su cabecera YAML): el filtro de remitentes debe descartarlo por
el remitente (`nu@nu.com.co`, fuera de la allowlist), nunca confundirlo con un
correo real de Davivienda por su contenido.
"""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

import pytest
import structlog.testing
from sqlalchemy import text
from support.email_fixtures import load_email_fixtures

from finanzia.modules.ingestion.application.dto import RawMessageInput
from finanzia.modules.ingestion.domain.enums import Channel
from finanzia.modules.ingestion.public import Discarded, ingest_raw_message
from finanzia.shared.clock import SystemClock

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable

    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
    from support.auth import AuthedUser

    from finanzia.shared.events.redis_streams import RedisStreamsEventBus

pytestmark = pytest.mark.integration

_OTHER_DIR = Path(__file__).resolve().parents[2] / "fixtures" / "emails" / "other"
_NU_FIXTURE = next(f for f in load_email_fixtures(_OTHER_DIR) if f.name == "nu_pago.txt")


async def test_remitente_no_soportado_se_descarta_sin_persistir_ni_loguear_el_cuerpo(
    session_factory: async_sessionmaker[AsyncSession],
    bus: RedisStreamsEventBus,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    assert _NU_FIXTURE.expected.get("discarded_by_sender_filter") is True

    with structlog.testing.capture_logs() as captured:
        async with session_factory() as session:
            outcome = await ingest_raw_message(
                session,
                bus,
                SystemClock(),
                RawMessageInput(
                    user_id=user.id,
                    channel=Channel.EMAIL,
                    external_id=_NU_FIXTURE.name,
                    sender=_NU_FIXTURE.sender,
                    title=_NU_FIXTURE.subject,
                    text=_NU_FIXTURE.body,
                    received_at=_NU_FIXTURE.received_at,
                ),
            )

    assert isinstance(outcome, Discarded)
    assert outcome.reason == "unsupported_sender"

    async with session_factory() as session:
        raw_count = (
            await session.execute(
                text("SELECT count(*) FROM raw_messages WHERE user_id = :u"), {"u": str(user.id)}
            )
        ).scalar_one()
    assert raw_count == 0

    for entry in captured:
        rendered = repr(entry)
        assert "CORREDORES" not in rendered
        assert _NU_FIXTURE.sender not in rendered
