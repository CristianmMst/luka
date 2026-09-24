"""Tests unitarios del aviso push y la sincronizacion por history (F3.4, spec 006 §2.1)."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from finanzia.modules.ingestion.application.use_cases.gmail_sync import (
    HandleGmailPush,
    SyncGmail,
)
from finanzia.modules.ingestion.application.use_cases.ingest_raw_message import IngestRawMessage
from finanzia.modules.ingestion.domain.entities import GmailConnection
from finanzia.modules.ingestion.domain.enums import Channel, GmailConnectionStatus
from finanzia.modules.ingestion.domain.errors import (
    GmailAuthRevoked,
    GmailRequestRejected,
    GmailSyncEnqueueFailed,
    GmailTransientError,
)
from finanzia.modules.ingestion.domain.gmail_push import GmailPushNotification
from ingestion.fakes import (
    FakeGmailClient,
    FakeSenderPolicy,
    FakeTokenCipher,
    FixedClock,
    InMemoryGmailConnectionRepo,
    InMemoryRawMessageRepo,
    NoopUoW,
    RecordingPublisher,
    RecordingSyncQueue,
    SequenceIdGenerator,
)

pytestmark = pytest.mark.unit

NOW = datetime(2026, 5, 1, 12, 0, tzinfo=UTC)
USER = uuid4()
BANK = "alertas@bancolombia.com.co"
CURSOR = 100


class _Deps:
    def __init__(self) -> None:
        self.connections = InMemoryGmailConnectionRepo()
        self.raw = InMemoryRawMessageRepo()
        self.gmail = FakeGmailClient(history_id=150)
        self.cipher = FakeTokenCipher()
        self.clock = FixedClock(NOW)
        self.uow = NoopUoW()
        self.events = RecordingPublisher()
        self.policy = FakeSenderPolicy(email_map={BANK: "bancolombia"})

    async def seed(self, **overrides: object) -> GmailConnection:
        values: dict[str, object] = {
            "user_id": USER,
            "email": "ana@gmail.com",
            "refresh_token_enc": self.cipher.encrypt(USER, "refresh-1"),
            "history_id": CURSOR,
            "watch_expires_at": NOW + timedelta(days=7),
            "status": GmailConnectionStatus.ACTIVE,
            "last_sync_at": None,
            "created_at": NOW,
            "updated_at": NOW,
        }
        values.update(overrides)
        connection = GmailConnection(**values)  # type: ignore[arg-type]
        await self.connections.upsert(connection)
        return connection

    def sync(self) -> SyncGmail:
        ingest = IngestRawMessage(
            repo=self.raw,
            policy=self.policy,
            events=self.events,
            clock=self.clock,
            ids=SequenceIdGenerator(),
            uow=self.uow,
        )
        return SyncGmail(
            repo=self.connections,
            gmail=self.gmail,
            cipher=self.cipher,
            ingest=ingest,
            clock=self.clock,
            uow=self.uow,
        )

    def stored(self) -> GmailConnection:
        return self.connections.by_user[USER]


# --- SyncGmail: history ---------------------------------------------------------------


async def test_ingiere_los_mensajes_nuevos_y_avanza_el_cursor() -> None:
    deps = _Deps()
    await deps.seed()
    received = datetime(2026, 5, 1, 11, 30, tzinfo=UTC)
    deps.gmail.history[CURSOR] = ["m1"]
    deps.gmail.add_message("m1", f"Bancolombia <{BANK}>", "Compra por $10.000", received)

    result = await deps.sync().execute(USER)

    (msg,) = deps.raw.by_id.values()
    assert (msg.channel, msg.external_id, msg.sender) == (Channel.EMAIL, "m1", BANK)
    assert (msg.bank, msg.body, msg.received_at) == ("bancolombia", "Compra por $10.000", received)
    assert len(deps.events.events) == 1
    assert deps.stored().history_id == 150
    assert deps.stored().last_sync_at == NOW
    assert (result.status, result.resync, result.fetched, result.accepted) == (
        "synced",
        False,
        1,
        1,
    )
    # Pide el access token, lista el history desde el cursor y lee cada mensaje.
    assert [op for op, _ in deps.gmail.calls] == ["access_token", "history", "get_message"]


async def test_remitente_no_bancario_se_descarta_sin_persistir() -> None:
    deps = _Deps()
    await deps.seed()
    deps.gmail.history[CURSOR] = ["m1"]
    deps.gmail.add_message("m1", "Tienda <promos@tienda.com>", "Oferta secreta")

    result = await deps.sync().execute(USER)

    assert deps.raw.by_id == {}
    assert deps.events.events == []
    assert (result.discarded, result.accepted) == (1, 0)
    assert deps.stored().history_id == 150  # el cursor avanza igual


async def test_aviso_duplicado_no_ingiere_dos_veces() -> None:
    deps = _Deps()
    await deps.seed()
    deps.gmail.history[CURSOR] = ["m1"]
    deps.gmail.history[150] = ["m1"]  # Gmail puede repetir un id entre ventanas
    deps.gmail.add_message("m1", BANK, "Compra")

    first = await deps.sync().execute(USER)
    second = await deps.sync().execute(USER)

    assert len(deps.raw.by_id) == 1
    assert (first.accepted, second.accepted, second.duplicates) == (1, 0, 1)


async def test_aviso_viejo_con_cursor_al_dia_no_llama_a_gmail() -> None:
    deps = _Deps()
    await deps.seed()

    result = await deps.sync().execute(USER, notified_history_id=CURSOR)

    assert result.status == "up_to_date"
    assert deps.gmail.calls == []


async def test_el_cursor_nunca_retrocede() -> None:
    deps = _Deps()
    await deps.seed()
    deps.gmail.history[CURSOR] = []
    deps.gmail.mailbox_history_id = 90  # Gmail responde un historyId menor al guardado

    await deps.sync().execute(USER)

    assert deps.stored().history_id == CURSOR


async def test_mensaje_borrado_entre_history_y_get_se_salta() -> None:
    deps = _Deps()
    await deps.seed()
    deps.gmail.history[CURSOR] = ["borrado", "m2"]
    deps.gmail.add_message("m2", BANK, "Compra")

    result = await deps.sync().execute(USER)

    assert (result.skipped, result.accepted) == (1, 1)
    assert deps.stored().history_id == 150


# --- SyncGmail: resync ----------------------------------------------------------------


async def test_history_404_hace_resync_de_7_dias_con_tope() -> None:
    deps = _Deps()
    await deps.seed()  # sin `history[CURSOR]`: el fake responde 404
    deps.gmail.recent = ["m1", "m2"]
    deps.gmail.add_message("m1", BANK, "Compra 1")
    deps.gmail.add_message("m2", BANK, "Compra 2")

    result = await deps.sync().execute(USER)

    assert result.resync is True
    assert result.accepted == 2
    assert ("recent", "7d/500") in deps.gmail.calls
    # El cursor nuevo es el historyId del perfil, pedido antes de listar.
    ops = [op for op, _ in deps.gmail.calls]
    assert ops.index("profile_history_id") < ops.index("recent")
    assert deps.stored().history_id == 150


async def test_conexion_sin_cursor_hace_resync() -> None:
    deps = _Deps()
    await deps.seed(history_id=None)
    deps.gmail.recent = []

    result = await deps.sync().execute(USER, notified_history_id=5)

    assert result.resync is True
    assert "history" not in [op for op, _ in deps.gmail.calls]
    assert deps.stored().history_id == 150


# --- SyncGmail: errores ---------------------------------------------------------------


async def test_invalid_grant_marca_la_conexion_revoked() -> None:
    deps = _Deps()
    await deps.seed()
    deps.gmail.errors["access_token"] = GmailAuthRevoked("token: invalid_grant")

    result = await deps.sync().execute(USER)

    assert result.status == "revoked"
    assert deps.stored().status is GmailConnectionStatus.REVOKED
    assert deps.stored().history_id == CURSOR


async def test_token_indescifrable_marca_la_conexion_error() -> None:
    deps = _Deps()
    await deps.seed(refresh_token_enc=deps.cipher.encrypt(uuid4(), "de-otro"))

    result = await deps.sync().execute(USER)

    assert result.status == "undecryptable"
    assert deps.stored().status is GmailConnectionStatus.ERROR
    assert deps.gmail.calls == []


@pytest.mark.parametrize("operation", ["access_token", "history"])
async def test_rechazo_permanente_marca_la_conexion_error_sin_propagar(operation: str) -> None:
    # Carry-in Task 5: `invalid_client` u otro rechazo permanente de Google en
    # `access_token`/`history.list` no se arregla reintentando (a diferencia de
    # `GmailTransientError`), asi que la conexion pasa a `error` sin que el job
    # se propague (nada de `Retry` de arq).
    deps = _Deps()
    await deps.seed()
    deps.gmail.history[CURSOR] = ["m1"]
    deps.gmail.errors[operation] = GmailRequestRejected(f"{operation}: invalid_client")

    result = await deps.sync().execute(USER)

    assert result.status == "error"
    assert deps.stored().status is GmailConnectionStatus.ERROR
    assert deps.stored().history_id == CURSOR  # el cursor no se toca


@pytest.mark.parametrize("operation", ["history", "get_message"])
async def test_error_transitorio_se_propaga_sin_avanzar_el_cursor(operation: str) -> None:
    deps = _Deps()
    await deps.seed()
    deps.gmail.history[CURSOR] = ["m1"]
    deps.gmail.add_message("m1", BANK, "Compra")
    deps.gmail.errors[operation] = GmailTransientError(f"{operation}: 503")

    with pytest.raises(GmailTransientError):
        await deps.sync().execute(USER)

    assert deps.stored().history_id == CURSOR
    assert deps.stored().last_sync_at is None


@pytest.mark.parametrize(
    ("status", "expected"),
    [(GmailConnectionStatus.REVOKED, "inactive"), (GmailConnectionStatus.ERROR, "inactive")],
)
async def test_conexion_no_activa_no_sincroniza(
    status: GmailConnectionStatus, expected: str
) -> None:
    deps = _Deps()
    await deps.seed(status=status)

    result = await deps.sync().execute(USER)

    assert result.status == expected
    assert deps.gmail.calls == []


async def test_sin_conexion_no_hace_nada() -> None:
    deps = _Deps()

    result = await deps.sync().execute(USER)

    assert result.status == "no_connection"
    assert deps.gmail.calls == []


async def test_no_llama_a_google_con_la_transaccion_de_lectura_abierta() -> None:
    deps = _Deps()
    await deps.seed()
    deps.gmail.history[CURSOR] = []
    commits_at_call: list[int] = []
    original = deps.gmail.access_token

    async def spy(refresh_token: str) -> str:
        commits_at_call.append(deps.uow.commits)
        return await original(refresh_token)

    deps.gmail.access_token = spy  # type: ignore[method-assign]

    await deps.sync().execute(USER)

    assert commits_at_call == [1]


async def test_reconexion_con_otra_cuenta_durante_el_sync_no_pisa_la_conexion_nueva() -> None:
    # El sync leyo la conexion vieja; si al terminar la fila es de otra cuenta, no la toca.
    deps = _Deps()
    await deps.seed()
    deps.gmail.errors["access_token"] = GmailAuthRevoked("token: invalid_grant")
    sync = deps.sync()
    original_get = deps.connections.get

    async def get_then_reconnect(user_id):  # type: ignore[no-untyped-def]
        found = await original_get(user_id)
        await deps.seed(email="nueva@gmail.com")
        return found

    deps.connections.get = get_then_reconnect  # type: ignore[method-assign]

    await sync.execute(USER)

    assert deps.stored().email == "nueva@gmail.com"
    assert deps.stored().status is GmailConnectionStatus.ACTIVE


# --- HandleGmailPush ------------------------------------------------------------------


async def test_push_encola_un_sync_por_conexion_activa_de_esa_cuenta() -> None:
    deps = _Deps()
    await deps.seed()
    queue = RecordingSyncQueue()

    jobs = await HandleGmailPush(repo=deps.connections, queue=queue, uow=deps.uow).execute(
        GmailPushNotification("ana@gmail.com", 777)
    )

    assert jobs == 1
    assert queue.jobs == [(USER, 777)]
    assert deps.uow.commits == 1  # cierra la lectura antes de tocar Redis


@pytest.mark.parametrize(
    ("email", "status"),
    [
        ("otra@gmail.com", GmailConnectionStatus.ACTIVE),
        ("ana@gmail.com", GmailConnectionStatus.REVOKED),
    ],
)
async def test_push_de_cuenta_desconocida_o_inactiva_no_encola(
    email: str, status: GmailConnectionStatus
) -> None:
    deps = _Deps()
    await deps.seed(status=status)
    queue = RecordingSyncQueue()

    jobs = await HandleGmailPush(repo=deps.connections, queue=queue, uow=deps.uow).execute(
        GmailPushNotification(email, 777)
    )

    assert jobs == 0
    assert queue.jobs == []


async def test_push_propaga_el_fallo_al_encolar() -> None:
    deps = _Deps()
    await deps.seed()
    queue = RecordingSyncQueue()
    queue.error = GmailSyncEnqueueFailed("redis caido")

    with pytest.raises(GmailSyncEnqueueFailed):
        await HandleGmailPush(repo=deps.connections, queue=queue, uow=deps.uow).execute(
            GmailPushNotification("ana@gmail.com", 777)
        )


async def test_otro_rechazo_de_messages_get_no_se_salta_ni_avanza_el_cursor() -> None:
    # Solo el 404 se salta: cualquier otro rechazo detiene la pasada sin perder el
    # mensaje (el cursor queda donde estaba y el proximo aviso lo reintenta).
    deps = _Deps()
    await deps.seed()
    deps.gmail.history[CURSOR] = ["m1"]
    deps.gmail.add_message("m1", BANK, "Compra")
    deps.gmail.errors["get_message"] = GmailRequestRejected("messages.get: respuesta ilegible")

    with pytest.raises(GmailRequestRejected):
        await deps.sync().execute(USER)

    assert deps.stored().history_id == CURSOR
    assert deps.stored().status is GmailConnectionStatus.ACTIVE
