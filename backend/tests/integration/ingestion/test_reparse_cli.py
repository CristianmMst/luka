"""Tests del CLI `python -m finanzia.tools.reparse` (spec 005 §7).

`main` se corre con `get_settings` apuntado a los settings de test (DB y Redis de
test): nunca toca la base de desarrollo. Solo imprime conteos.
"""

import asyncio
from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.raw_messages import insert_raw_message

from finanzia.shared.settings import Settings
from finanzia.tools import reparse

pytestmark = pytest.mark.integration


async def test_main_reencola_desde_la_fecha_e_imprime_solo_el_conteo(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    redis_clean: None,
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
) -> None:
    del redis_clean
    user = await user_factory()
    now = datetime.now(UTC)
    reciente = await insert_raw_message(
        session_factory, user_id=user.id, status="failed", received_at=now
    )
    viejo = await insert_raw_message(
        session_factory, user_id=user.id, status="failed", received_at=now - timedelta(days=30)
    )
    monkeypatch.setattr(reparse, "get_settings", lambda: settings)

    since = (now - timedelta(days=2)).date().isoformat()
    # `main` corre su propio `asyncio.run`: en un hilo, fuera del loop de pytest-asyncio.
    code = await asyncio.to_thread(reparse.main, ["--since", since])

    assert code == 0
    assert capsys.readouterr().out.strip() == "reparsed=1"
    async with session_factory() as session:
        rows = (
            await session.execute(
                text("SELECT id, status FROM raw_messages WHERE user_id = :u"), {"u": user.id}
            )
        ).all()
    statuses = {row.id: row.status for row in rows}
    assert statuses == {reciente: "pending", viejo: "failed"}
