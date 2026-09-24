"""Tests de integracion del job `sync_gmail` (F3.4, spec 006 §2.1).

Corre `ingestion.public.run_gmail_sync` (el cuerpo del job del worker) contra
Postgres y Redis de test, con el `GoogleGmailClient` real sobre
`httpx.MockTransport` (`FakeGoogle`): lock, history, resync, filtro de
remitentes, ingesta idempotente y cursor.
"""

from __future__ import annotations

from collections.abc import AsyncGenerator, Awaitable, Callable
from datetime import UTC, datetime
from typing import Any
from uuid import UUID

import httpx
import pytest
import redis.asyncio as redis_asyncio
import structlog.testing
from redis.asyncio import Redis
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.fake_google import ACCOUNT_EMAIL, HISTORY_ID, REFRESH_TOKEN, FakeGoogle
from support.gmail_connections import insert_gmail_connection

from finanzia.events_registry import build_registry
from finanzia.modules.ingestion import public as ingestion_public
from finanzia.modules.ingestion.domain.entities import GmailConnection
from finanzia.modules.ingestion.domain.enums import GmailConnectionStatus
from finanzia.modules.ingestion.infrastructure.gmail_client import (
    GoogleGmailClient,
    build_gmail_client,
)
from finanzia.modules.ingestion.infrastructure.repositories import (
    SqlAlchemyGmailConnectionRepository,
)
from finanzia.modules.ingestion.infrastructure.token_cipher import AesGcmTokenCipher
from finanzia.shared.clock import SystemClock
from finanzia.shared.events.memory import InMemoryEventBus
from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration

_BANK = "alertasynotificaciones@an.notificacionesbancolombia.com"
_BANK_BODY = "Bancolombia: Compraste $52.300,00 en TIENDA SECRETA con tu T.Deb *1234"
_SPAM_SENDER = "promos-secretas@tienda.example.com"
_SPAM_BODY = "Oferta confidencial solo para ti"
#: `internalDate` de los mensajes de prueba: 2026-05-01T12:00:00Z en ms.
_INTERNAL_MS = 1_777_636_800_000


@pytest.fixture
def google() -> FakeGoogle:
    return FakeGoogle()


@pytest.fixture
async def gmail(settings: Settings, google: FakeGoogle) -> AsyncGenerator[GoogleGmailClient, None]:
    async with httpx.AsyncClient(transport=google.transport()) as http:
        yield build_gmail_client(settings, http)


@pytest.fixture
async def redis_client(settings: Settings, redis_clean: None) -> AsyncGenerator[Redis, None]:
    del redis_clean
    client = redis_asyncio.from_url(str(settings.redis_url))
    try:
        yield client
    finally:
        await client.aclose()


@pytest.fixture
def bus() -> InMemoryEventBus:
    return InMemoryEventBus(build_registry())


@pytest.fixture
async def user(
    user_factory: Callable[..., Awaitable[AuthedUser]],
    session_factory: async_sessionmaker[AsyncSession],
    settings: Settings,
) -> AuthedUser:
    authed = await user_factory()
    await insert_gmail_connection(
        session_factory,
        user_id=authed.id,
        email=ACCOUNT_EMAIL,
        refresh_token_enc=AesGcmTokenCipher.from_settings(settings).encrypt(
            authed.id, REFRESH_TOKEN
        ),
        history_id=HISTORY_ID,
    )
    return authed


RunSync = Callable[..., Awaitable[list[ingestion_public.GmailSyncResult]]]


@pytest.fixture
def run_sync(
    session_factory: async_sessionmaker[AsyncSession],
    redis_client: Redis,
    bus: InMemoryEventBus,
    gmail: GoogleGmailClient,
    settings: Settings,
) -> RunSync:
    async def run(user_id: UUID, history_id: int | None = None) -> list[Any]:
        return await ingestion_public.run_gmail_sync(
            session_factory=session_factory,
            redis_client=redis_client,
            event_bus=bus,
            gmail=gmail,
            clock=SystemClock(),
            settings=settings,
            user_id=user_id,
            history_id=history_id,
        )

    return run


async def _connection(
    session_factory: async_sessionmaker[AsyncSession], user_id: UUID
) -> GmailConnection:
    async with session_factory() as session:
        found = await SqlAlchemyGmailConnectionRepository(session).get(user_id)
    assert found is not None
    return found


async def _raw_messages(
    session_factory: async_sessionmaker[AsyncSession], user_id: UUID
) -> list[dict[str, object]]:
    async with session_factory() as session:
        rows = await session.execute(
            text(
                "SELECT channel, external_id, sender, bank, body, received_at "
                "FROM raw_messages WHERE user_id = :u ORDER BY external_id"
            ),
            {"u": user_id},
        )
    return [dict(row._mapping) for row in rows]


async def test_ingiere_el_correo_del_banco_descarta_el_resto_y_avanza_el_cursor(
    google: FakeGoogle,
    user: AuthedUser,
    run_sync: RunSync,
    bus: InMemoryEventBus,
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    google.history[HISTORY_ID] = ["m-banco", "m-spam"]
    google.add_message("m-banco", f"Bancolombia <{_BANK}>", _BANK_BODY, _INTERNAL_MS)
    google.add_message("m-spam", f"Tienda <{_SPAM_SENDER}>", _SPAM_BODY, _INTERNAL_MS)

    with structlog.testing.capture_logs() as captured:
        (result,) = await run_sync(user.id, google.mailbox_history_id)

    assert (result.status, result.accepted, result.discarded) == ("synced", 1, 1)
    assert await _raw_messages(session_factory, user.id) == [
        {
            "channel": "email",
            "external_id": "m-banco",
            "sender": _BANK,
            "bank": "bancolombia",
            "body": _BANK_BODY,
            "received_at": datetime(2026, 5, 1, 12, 0, tzinfo=UTC),
        }
    ]
    assert len(bus.published) == 1
    connection = await _connection(session_factory, user.id)
    assert connection.history_id == google.mailbox_history_id
    assert connection.last_sync_at is not None
    # Logs: solo metadatos; nunca la cuenta, remitentes, cuerpos ni tokens (spec 009 §5).
    for entry in captured:
        rendered = repr(entry)
        for secret in (ACCOUNT_EMAIL, _BANK, _SPAM_SENDER, _BANK_BODY, _SPAM_BODY, REFRESH_TOKEN):
            assert secret not in rendered


async def test_aviso_duplicado_no_ingiere_dos_veces(
    google: FakeGoogle,
    user: AuthedUser,
    run_sync: RunSync,
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    google.history[HISTORY_ID] = ["m-banco"]
    google.add_message("m-banco", _BANK, _BANK_BODY)

    await run_sync(user.id, google.mailbox_history_id)
    # Pub/Sub reentrega el mismo aviso y la conexion ya esta al dia: ni llama a Gmail.
    calls_before = len(google.requests)
    (again,) = await run_sync(user.id, google.mailbox_history_id)
    calls_after_again = len(google.requests)
    # Otro aviso cuyo history repite el mismo mensaje: se ingiere como duplicado.
    google.history[google.mailbox_history_id] = ["m-banco"]
    google.mailbox_history_id += 10
    (third,) = await run_sync(user.id, google.mailbox_history_id)

    assert again.status == "up_to_date"
    assert calls_after_again == calls_before
    assert (third.accepted, third.duplicates) == (0, 1)
    assert len(await _raw_messages(session_factory, user.id)) == 1


async def test_cursor_vencido_hace_resync_de_los_ultimos_7_dias(
    google: FakeGoogle,
    user: AuthedUser,
    run_sync: RunSync,
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    # Sin `history[HISTORY_ID]`: history.list responde 404.
    google.recent = ["m-banco"]
    google.add_message("m-banco", _BANK, _BANK_BODY)

    (result,) = await run_sync(user.id)

    assert (result.resync, result.accepted) == (True, 1)
    assert google.operations()[:4] == ["refresh", "history", "profile", "messages"]
    messages_query = google.requests[3][1]
    assert messages_query["q"] == "in:inbox newer_than:7d"
    connection = await _connection(session_factory, user.id)
    assert connection.history_id == google.mailbox_history_id


async def test_invalid_grant_marca_la_conexion_revoked(
    google: FakeGoogle,
    user: AuthedUser,
    run_sync: RunSync,
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    google.status_by_operation["refresh"] = 400  # invalid_grant

    (result,) = await run_sync(user.id)

    assert result.status == "revoked"
    connection = await _connection(session_factory, user.id)
    assert connection.status is GmailConnectionStatus.REVOKED
    assert connection.history_id == HISTORY_ID


async def test_rechazo_permanente_en_refresh_marca_la_conexion_error(
    google: FakeGoogle,
    user: AuthedUser,
    run_sync: RunSync,
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    """Carry-in Task 5: un rechazo permanente de Google (p. ej. `invalid_client`,
    aqui un 403 generico que no es `invalid_grant`) al pedir el access token marca
    la conexion `error` sin propagar (nada que reintentar via arq).
    """
    google.status_by_operation["refresh"] = 403

    (result,) = await run_sync(user.id)

    assert result.status == "error"
    connection = await _connection(session_factory, user.id)
    assert connection.status is GmailConnectionStatus.ERROR
    assert connection.history_id == HISTORY_ID  # el cursor no se toca


async def test_error_transitorio_se_propaga_y_suelta_el_lock(
    google: FakeGoogle,
    user: AuthedUser,
    run_sync: RunSync,
    redis_client: Redis,
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    google.history[HISTORY_ID] = []
    google.status_by_operation["history"] = 503

    with pytest.raises(ingestion_public.GmailTransientError):
        await run_sync(user.id)

    assert await redis_client.exists(f"gmail_sync:lock:{user.id}") == 0
    assert (await _connection(session_factory, user.id)).history_id == HISTORY_ID
    del google.status_by_operation["history"]
    (result,) = await run_sync(user.id)
    assert result.status == "synced"


async def test_con_el_lock_tomado_sale_sin_llamar_a_gmail_y_deja_pendiente(
    google: FakeGoogle, user: AuthedUser, run_sync: RunSync, redis_client: Redis
) -> None:
    await redis_client.set(f"gmail_sync:lock:{user.id}", b"otro-job", ex=60)

    assert await run_sync(user.id, 1) == []

    assert google.requests == []
    # El dueno del lock vera la marca al soltarlo y hara otra pasada.
    assert await redis_client.exists(f"gmail_sync:pending:{user.id}") == 1


class _PushDuringSync:
    """Envuelve el cliente Gmail: el primer `get_message` simula un push concurrente
    (otro job que encuentra el lock tomado y deja la marca `pending`).
    """

    def __init__(self, inner: GoogleGmailClient, redis_client: Redis, user_id: UUID) -> None:
        self._inner = inner
        self._redis = redis_client
        self._pending_key = f"gmail_sync:pending:{user_id}"
        self._fired = False

    def __getattr__(self, name: str) -> Any:
        return getattr(self._inner, name)

    async def get_message(self, access_token: str, message_id: str) -> Any:
        if not self._fired:
            self._fired = True
            await self._redis.set(self._pending_key, b"1", ex=60)
        return await self._inner.get_message(access_token, message_id)


async def test_aviso_durante_un_sync_provoca_otra_pasada(  # noqa: PLR0913, PLR0917 - fixtures
    google: FakeGoogle,
    user: AuthedUser,
    gmail: GoogleGmailClient,
    redis_client: Redis,
    bus: InMemoryEventBus,
    settings: Settings,
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    first_cursor = google.mailbox_history_id
    google.history[HISTORY_ID] = ["m-1"]
    google.history[first_cursor] = ["m-2"]
    google.add_message("m-1", _BANK, _BANK_BODY)
    google.add_message("m-2", _BANK, "Bancolombia: Transferiste $10.000")

    results = await ingestion_public.run_gmail_sync(
        session_factory=session_factory,
        redis_client=redis_client,
        event_bus=bus,
        gmail=_PushDuringSync(gmail, redis_client, user.id),  # type: ignore[arg-type]
        clock=SystemClock(),
        settings=settings,
        user_id=user.id,
        history_id=None,
    )

    assert [(r.status, r.accepted) for r in results] == [("synced", 1), ("synced", 1)]
    rows = await _raw_messages(session_factory, user.id)
    assert [row["external_id"] for row in rows] == ["m-1", "m-2"]
    assert await redis_client.exists(f"gmail_sync:pending:{user.id}") == 0
    assert await redis_client.exists(f"gmail_sync:lock:{user.id}") == 0
