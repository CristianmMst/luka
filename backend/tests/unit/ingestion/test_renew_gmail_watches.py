"""Tests unitarios de la renovacion diaria de watches de Gmail (F3.5, spec 006 §2.1)."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import cast
from uuid import UUID, uuid4

import pytest

from finanzia.modules.ingestion.application.dto import RenewWatchesSummary
from finanzia.modules.ingestion.application.use_cases.gmail_sync import SyncGmail
from finanzia.modules.ingestion.application.use_cases.ingest_raw_message import IngestRawMessage
from finanzia.modules.ingestion.application.use_cases.renew_gmail_watches import (
    EXPIRING_WITHIN_DEFAULT,
    RenewGmailWatches,
)
from finanzia.modules.ingestion.domain.entities import GmailConnection
from finanzia.modules.ingestion.domain.enums import GmailConnectionStatus
from finanzia.modules.ingestion.domain.errors import (
    GmailAuthRevoked,
    GmailRequestRejected,
    GmailTransientError,
)
from ingestion.fakes import (
    FakeGmailClient,
    FakeSenderPolicy,
    FakeTokenCipher,
    FixedClock,
    InMemoryGmailConnectionRepo,
    InMemoryRawMessageRepo,
    NoopUoW,
    RecordingPublisher,
    SequenceIdGenerator,
)

pytestmark = pytest.mark.unit

NOW = datetime(2026, 5, 1, 12, 0, tzinfo=UTC)
TOPIC = "projects/finanzia-509500/topics/gmail-push"
BANK = "alertas@bancolombia.com.co"


class _Deps:
    def __init__(self) -> None:
        self.connections = InMemoryGmailConnectionRepo()
        self.gmail = FakeGmailClient(history_id=999)
        self.cipher = FakeTokenCipher()
        self.clock = FixedClock(NOW)
        self.uow = NoopUoW()

    async def seed(self, **overrides: object) -> GmailConnection:
        user_id = cast("UUID", overrides.pop("user_id", uuid4()))
        values: dict[str, object] = {
            "user_id": user_id,
            "email": "ana@gmail.com",
            "refresh_token_enc": self.cipher.encrypt(user_id, "refresh-1"),
            "history_id": 100,
            "watch_expires_at": NOW + timedelta(hours=10),  # vence en < 48h
            "status": GmailConnectionStatus.ACTIVE,
            "last_sync_at": None,
            "created_at": NOW,
            "updated_at": NOW,
        }
        values.update(overrides)
        connection = GmailConnection(**values)  # type: ignore[arg-type]
        await self.connections.upsert(connection)
        return connection

    def use_case(self) -> RenewGmailWatches:
        return RenewGmailWatches(
            repo=self.connections,
            gmail=self.gmail,
            cipher=self.cipher,
            clock=self.clock,
            uow=self.uow,
            topic=TOPIC,
        )

    def stored(self, user_id: object) -> GmailConnection:
        return self.connections.by_user[user_id]  # type: ignore[index]


async def test_renueva_una_conexion_activa_por_vencer() -> None:
    deps = _Deps()
    connection = await deps.seed()
    deps.gmail.watch_expires_at = NOW + timedelta(days=7)

    summary = await deps.use_case().execute()

    assert (summary.renewed, summary.revoked, summary.errored) == (1, 0, 0)
    stored = deps.stored(connection.user_id)
    assert stored.watch_expires_at == NOW + timedelta(days=7)
    assert stored.status is GmailConnectionStatus.ACTIVE
    assert [op for op, _ in deps.gmail.calls] == ["access_token", "watch"]
    assert deps.gmail.calls[1] == ("watch", TOPIC)


async def test_no_renueva_conexion_activa_que_no_vence_pronto() -> None:
    deps = _Deps()
    await deps.seed(watch_expires_at=NOW + timedelta(days=6))

    summary = await deps.use_case().execute()

    assert (summary.renewed, summary.revoked, summary.errored) == (0, 0, 0)
    assert deps.gmail.calls == []


async def test_no_renueva_conexion_revocada() -> None:
    deps = _Deps()
    await deps.seed(status=GmailConnectionStatus.REVOKED)

    summary = await deps.use_case().execute()

    assert (summary.renewed, summary.revoked, summary.errored) == (0, 0, 0)
    assert deps.gmail.calls == []


async def test_conexion_en_error_sin_watch_se_recupera_a_active() -> None:
    # Connect dejo `error` con watch NULL (fallo transitorio al crear el watch).
    deps = _Deps()
    connection = await deps.seed(
        status=GmailConnectionStatus.ERROR, watch_expires_at=None, history_id=None
    )
    deps.gmail.watch_expires_at = NOW + timedelta(days=7)

    summary = await deps.use_case().execute()

    assert summary.renewed == 1
    stored = deps.stored(connection.user_id)
    assert stored.status is GmailConnectionStatus.ACTIVE
    assert stored.watch_expires_at == NOW + timedelta(days=7)
    assert stored.history_id == 999  # cursor nulo: el watch lo siembra


async def test_conexion_en_error_con_watch_por_vencer_se_recupera() -> None:
    deps = _Deps()
    connection = await deps.seed(status=GmailConnectionStatus.ERROR)

    summary = await deps.use_case().execute()

    assert summary.renewed == 1
    assert deps.stored(connection.user_id).status is GmailConnectionStatus.ACTIVE


async def test_conexion_en_error_con_watch_lejano_no_se_toca() -> None:
    deps = _Deps()
    await deps.seed(status=GmailConnectionStatus.ERROR, watch_expires_at=NOW + timedelta(days=6))

    summary = await deps.use_case().execute()

    assert summary == RenewWatchesSummary()
    assert deps.gmail.calls == []


async def test_el_cursor_nunca_retrocede_al_renovar() -> None:
    deps = _Deps()
    connection = await deps.seed(history_id=500)
    deps.gmail.history_id = 100  # Gmail responde un historyId menor al guardado

    await deps.use_case().execute()

    assert deps.stored(connection.user_id).history_id == 500


async def test_el_cursor_no_avanza_aunque_watch_traiga_uno_mayor() -> None:
    # `users.watch` devuelve el historyId actual del buzon: adelantar el cursor
    # saltaria los correos que aun no se sincronizaron.
    deps = _Deps()
    connection = await deps.seed(history_id=100)
    deps.gmail.history_id = 500

    await deps.use_case().execute()

    assert deps.stored(connection.user_id).history_id == 100


async def test_push_pendiente_se_ingiere_aunque_la_renovacion_corra_antes() -> None:
    """Regresion B1: push encolado -> renovacion -> sync ingiere el mensaje."""
    deps = _Deps()
    connection = await deps.seed(history_id=100)
    deps.gmail.history_id = 500  # historyId actual que devuelve `watch`
    deps.gmail.mailbox_history_id = 500
    deps.gmail.history[100] = ["m-1"]
    deps.gmail.add_message("m-1", BANK, "Compraste $10.000 en TIENDA")
    notified_history_id = 500  # el aviso encolado, aun sin procesar

    await deps.use_case().execute()
    raw = InMemoryRawMessageRepo()
    ingest = IngestRawMessage(
        repo=raw,
        policy=FakeSenderPolicy(email_map={BANK: "bancolombia"}),
        events=RecordingPublisher(),
        clock=deps.clock,
        ids=SequenceIdGenerator(),
        uow=deps.uow,
    )
    sync = SyncGmail(
        repo=deps.connections,
        gmail=deps.gmail,
        cipher=deps.cipher,
        ingest=ingest,
        clock=deps.clock,
        uow=deps.uow,
    )

    result = await sync.execute(connection.user_id, notified_history_id)

    assert (result.status, result.accepted) == ("synced", 1)
    assert [m.external_id for m in raw.by_id.values()] == ["m-1"]
    assert deps.stored(connection.user_id).history_id == 500


async def test_invalid_grant_marca_la_conexion_revoked() -> None:
    deps = _Deps()
    connection = await deps.seed()
    deps.gmail.errors["access_token"] = GmailAuthRevoked("token: invalid_grant")

    summary = await deps.use_case().execute()

    assert (summary.renewed, summary.revoked, summary.errored) == (0, 1, 0)
    assert deps.stored(connection.user_id).status is GmailConnectionStatus.REVOKED


async def test_error_transitorio_no_cambia_el_estado_y_sigue_con_las_demas() -> None:
    deps = _Deps()
    fallida = await deps.seed()
    deps.gmail.errors["watch"] = GmailTransientError("watch: 503")

    summary = await deps.use_case().execute()

    assert summary == RenewWatchesSummary(deferred=1)
    stored = deps.stored(fallida.user_id)
    assert stored.status is GmailConnectionStatus.ACTIVE
    assert stored.watch_expires_at == fallida.watch_expires_at


async def test_error_transitorio_deja_en_error_a_una_conexion_en_error() -> None:
    deps = _Deps()
    connection = await deps.seed(status=GmailConnectionStatus.ERROR, watch_expires_at=None)
    deps.gmail.errors["access_token"] = GmailTransientError("token: 503")

    summary = await deps.use_case().execute()

    assert summary.deferred == 1
    assert deps.stored(connection.user_id).status is GmailConnectionStatus.ERROR


async def test_rechazo_marca_error() -> None:
    deps = _Deps()
    connection = await deps.seed()
    deps.gmail.errors["watch"] = GmailRequestRejected("watch: 400")

    summary = await deps.use_case().execute()

    assert (summary.renewed, summary.revoked, summary.errored) == (0, 0, 1)
    assert deps.stored(connection.user_id).status is GmailConnectionStatus.ERROR


async def test_token_indescifrable_marca_error_sin_llamar_a_gmail() -> None:
    deps = _Deps()
    connection = await deps.seed(refresh_token_enc=deps.cipher.encrypt(uuid4(), "de-otro"))

    summary = await deps.use_case().execute()

    assert (summary.renewed, summary.revoked, summary.errored) == (0, 0, 1)
    assert deps.stored(connection.user_id).status is GmailConnectionStatus.ERROR
    assert deps.gmail.calls == []


async def test_una_conexion_fallida_no_corta_las_demas() -> None:
    deps = _Deps()
    fallida_id, sana_id = uuid4(), uuid4()
    fallida = await deps.seed(
        user_id=fallida_id,
        email="falla@gmail.com",
        refresh_token_enc=deps.cipher.encrypt(fallida_id, "refresh-mala"),
    )
    sana = await deps.seed(
        user_id=sana_id,
        email="sana@gmail.com",
        refresh_token_enc=deps.cipher.encrypt(sana_id, "refresh-buena"),
    )

    original = deps.gmail.access_token

    async def fails_only_for_mala(refresh_token: str) -> str:
        if refresh_token == "refresh-mala":
            raise GmailAuthRevoked("token: invalid_grant")
        return await original(refresh_token)

    deps.gmail.access_token = fails_only_for_mala  # type: ignore[method-assign]

    summary = await deps.use_case().execute()

    assert (summary.renewed, summary.revoked, summary.errored) == (1, 1, 0)
    assert deps.stored(fallida.user_id).status is GmailConnectionStatus.REVOKED
    assert deps.stored(sana.user_id).status is GmailConnectionStatus.ACTIVE


async def test_no_llama_a_google_con_la_transaccion_de_lectura_abierta() -> None:
    deps = _Deps()
    await deps.seed()
    commits_at_call: list[int] = []
    original = deps.gmail.access_token

    async def spy(refresh_token: str) -> str:
        commits_at_call.append(deps.uow.commits)
        return await original(refresh_token)

    deps.gmail.access_token = spy  # type: ignore[method-assign]

    await deps.use_case().execute()

    assert commits_at_call == [1]


async def test_ventana_por_defecto_es_48h() -> None:
    assert EXPIRING_WITHIN_DEFAULT == timedelta(hours=48)
