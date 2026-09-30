"""Tests de integracion de `IngestionRawMessageGateway` (D2, D6), sobre Postgres real."""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime
from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.raw_messages import insert_raw_message

from luka.modules.parsing.application.dto import RawMessageView
from luka.modules.parsing.infrastructure.raw_message_gateway import IngestionRawMessageGateway

pytestmark = pytest.mark.integration

_NOW = datetime(2026, 9, 21, 12, 0, tzinfo=UTC)


async def test_get_for_parsing_devuelve_la_vista_con_enums_como_str(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(
        session_factory,
        user_id=user.id,
        channel="email",
        bank="bancolombia",
        status="pending",
    )

    async with session_factory() as session:
        gateway = IngestionRawMessageGateway(session)
        view = await gateway.get_for_parsing(raw_message_id)

    assert view is not None
    assert isinstance(view, RawMessageView)
    assert view.id == raw_message_id
    assert view.user_id == user.id
    assert view.channel == "email"
    assert isinstance(view.channel, str)
    assert view.status == "pending"
    assert isinstance(view.status, str)
    assert view.bank == "bancolombia"
    assert view.body is not None


async def test_get_for_parsing_devuelve_none_si_no_existe(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        gateway = IngestionRawMessageGateway(session)
        view = await gateway.get_for_parsing(uuid4())

    assert view is None


async def test_mark_cambia_el_estado_tras_commit(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id, status="pending")

    async with session_factory() as session:
        gateway = IngestionRawMessageGateway(session)
        marked = await gateway.mark(raw_message_id, "parsed", _NOW)
        await session.commit()

    assert marked is True

    async with session_factory() as session:
        gateway = IngestionRawMessageGateway(session)
        view = await gateway.get_for_parsing(raw_message_id)

    assert view is not None
    assert view.status == "parsed"


async def test_mark_es_idempotente_marcar_el_mismo_estado_dos_veces_no_lanza(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(session_factory, user_id=user.id, status="pending")

    async with session_factory() as session:
        gateway = IngestionRawMessageGateway(session)
        first = await gateway.mark(raw_message_id, "failed", _NOW)
        await session.commit()
    async with session_factory() as session:
        gateway = IngestionRawMessageGateway(session)
        second = await gateway.mark(raw_message_id, "failed", _NOW)
        await session.commit()

    assert first is True
    assert second is True


async def test_mark_de_un_id_inexistente_devuelve_false(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        gateway = IngestionRawMessageGateway(session)
        marked = await gateway.mark(uuid4(), "parsed", _NOW)
        await session.commit()

    assert marked is False
