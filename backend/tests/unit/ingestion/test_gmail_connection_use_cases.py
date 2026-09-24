"""Tests unitarios de conectar, desconectar y consultar Gmail (F3.3, spec 005 §3)."""

from datetime import UTC, datetime
from uuid import uuid4

import pytest

from finanzia.modules.ingestion.application.use_cases.gmail_connection import (
    ConnectGmail,
    DisconnectGmail,
    GetGmailStatus,
)
from finanzia.modules.ingestion.domain.entities import GmailConnection
from finanzia.modules.ingestion.domain.enums import GmailConnectionStatus
from finanzia.modules.ingestion.domain.errors import (
    GmailAuthRevoked,
    GmailRefreshTokenMissing,
    GmailRequestRejected,
    GmailScopeNotGranted,
    GmailTransientError,
    InvalidServerAuthCode,
)
from ingestion.fakes import (
    FakeGmailClient,
    FakeTokenCipher,
    FixedClock,
    InMemoryGmailConnectionRepo,
    NoopUoW,
)

pytestmark = pytest.mark.unit

NOW = datetime(2026, 5, 1, 12, 0, tzinfo=UTC)
TOPIC = "projects/p/topics/gmail-push"
USER = uuid4()


class _Deps:
    def __init__(self) -> None:
        self.repo = InMemoryGmailConnectionRepo()
        self.gmail = FakeGmailClient()
        self.cipher = FakeTokenCipher()
        self.clock = FixedClock(NOW)
        self.uow = NoopUoW()

    def connect(self) -> ConnectGmail:
        return ConnectGmail(
            repo=self.repo,
            gmail=self.gmail,
            cipher=self.cipher,
            clock=self.clock,
            uow=self.uow,
            topic=TOPIC,
        )

    def disconnect(self) -> DisconnectGmail:
        return DisconnectGmail(repo=self.repo, gmail=self.gmail, cipher=self.cipher, uow=self.uow)

    def status(self) -> GetGmailStatus:
        return GetGmailStatus(repo=self.repo)

    async def seed(self, **overrides: object) -> GmailConnection:
        values: dict[str, object] = {
            "user_id": USER,
            "email": "ana@gmail.com",
            "refresh_token_enc": self.cipher.encrypt(USER, "refresh-viejo"),
            "history_id": 10,
            "watch_expires_at": NOW,
            "status": GmailConnectionStatus.ACTIVE,
            "last_sync_at": NOW,
            "created_at": NOW,
            "updated_at": NOW,
        }
        values.update(overrides)
        connection = GmailConnection(**values)  # type: ignore[arg-type]
        await self.repo.upsert(connection)
        return connection


# --- ConnectGmail ---------------------------------------------------------------------


async def test_connect_canjea_cifra_guarda_y_crea_el_watch() -> None:
    deps = _Deps()

    view = await deps.connect().execute(USER, "code-1")

    stored = deps.repo.by_user[USER]
    assert stored.status is GmailConnectionStatus.ACTIVE
    assert stored.email == "ana@gmail.com"
    assert stored.history_id == deps.gmail.history_id
    assert stored.watch_expires_at == deps.gmail.watch_expires_at
    assert stored.last_sync_at is None
    assert stored.created_at == NOW
    assert stored.updated_at == NOW
    # Solo se guarda cifrado (atado al usuario), nunca en claro.
    assert b"refresh-1" != stored.refresh_token_enc
    assert deps.cipher.decrypt(USER, stored.refresh_token_enc) == "refresh-1"
    # Uno cierra la lectura de la conexion previa (antes de llamar a Google) y otro
    # confirma el upsert.
    assert deps.uow.commits == 2
    assert deps.gmail.calls == [
        ("exchange_code", "code-1"),
        ("access_token", "refresh-1"),
        ("watch", TOPIC),
    ]
    assert view.status == "active"
    assert view.email == "ana@gmail.com"
    assert view.watch_expires_at == deps.gmail.watch_expires_at
    assert view.last_sync_at is None


async def test_connect_con_codigo_invalido_lanza_invalid_server_auth_code_sin_guardar() -> None:
    deps = _Deps()
    deps.gmail.errors["exchange_code"] = GmailAuthRevoked("token: invalid_grant")

    with pytest.raises(InvalidServerAuthCode):
        await deps.connect().execute(USER, "code-usado")

    assert deps.repo.by_user == {}
    assert deps.uow.commits == 0


@pytest.mark.parametrize(
    "error",
    [GmailRefreshTokenMissing("sin refresh"), GmailTransientError("token: 503")],
)
async def test_connect_propaga_otros_fallos_del_canje_sin_guardar(error: Exception) -> None:
    deps = _Deps()
    deps.gmail.errors["exchange_code"] = error

    with pytest.raises(type(error)):
        await deps.connect().execute(USER, "code-1")

    assert deps.repo.by_user == {}
    assert deps.uow.commits == 0


@pytest.mark.parametrize(
    "error", [GmailTransientError("watch: 503"), GmailRequestRejected("watch: 403")]
)
async def test_connect_con_watch_fallido_guarda_la_conexion_en_error(error: Exception) -> None:
    deps = _Deps()
    deps.gmail.errors["watch"] = error

    view = await deps.connect().execute(USER, "code-1")

    stored = deps.repo.by_user[USER]
    assert stored.status is GmailConnectionStatus.ERROR
    assert stored.history_id is None
    assert stored.watch_expires_at is None
    assert deps.cipher.decrypt(USER, stored.refresh_token_enc) == "refresh-1"
    assert deps.uow.commits == 2
    assert view.status == "error"
    assert view.watch_expires_at is None


async def test_connect_con_refresh_revocado_al_pedir_access_token_queda_revoked() -> None:
    deps = _Deps()
    deps.gmail.errors["access_token"] = GmailAuthRevoked("token: invalid_grant")

    view = await deps.connect().execute(USER, "code-1")

    assert deps.repo.by_user[USER].status is GmailConnectionStatus.REVOKED
    assert view.status == "revoked"


async def test_reconectar_reemplaza_la_conexion_y_conserva_created_at() -> None:
    deps = _Deps()
    first = datetime(2026, 1, 1, tzinfo=UTC)
    await deps.seed(status=GmailConnectionStatus.REVOKED, created_at=first, updated_at=first)
    deps.gmail.refresh_token = "refresh-nuevo"

    await deps.connect().execute(USER, "code-2")

    stored = deps.repo.by_user[USER]
    assert stored.status is GmailConnectionStatus.ACTIVE
    assert deps.cipher.decrypt(USER, stored.refresh_token_enc) == "refresh-nuevo"
    assert stored.created_at == first
    assert stored.updated_at == NOW


async def test_reconectar_con_otra_cuenta_detiene_y_revoca_el_grant_viejo() -> None:
    deps = _Deps()
    await deps.seed(email="vieja@gmail.com")
    deps.gmail.refresh_token = "refresh-nuevo"

    await deps.connect().execute(USER, "code-2")

    assert deps.gmail.calls == [
        ("exchange_code", "code-2"),
        ("access_token", "refresh-viejo"),
        ("stop", "access-for-refresh-viejo"),
        ("revoke", "refresh-viejo"),
        ("access_token", "refresh-nuevo"),
        ("watch", TOPIC),
    ]
    stored = deps.repo.by_user[USER]
    assert stored.email == "ana@gmail.com"
    assert deps.cipher.decrypt(USER, stored.refresh_token_enc) == "refresh-nuevo"


async def test_reconectar_con_otra_cuenta_tolera_que_google_falle_al_limpiar() -> None:
    deps = _Deps()
    await deps.seed(email="vieja@gmail.com")
    deps.gmail.errors["revoke"] = GmailTransientError("revoke: 503")

    view = await deps.connect().execute(USER, "code-2")

    # La limpieza del grant viejo es best effort: la conexion nueva queda activa.
    assert view.status == "active"
    assert deps.repo.by_user[USER].email == "ana@gmail.com"


async def test_reconectar_con_otra_cuenta_y_token_viejo_indescifrable_no_llama_a_google() -> None:
    deps = _Deps()
    await deps.seed(
        email="vieja@gmail.com", refresh_token_enc=deps.cipher.encrypt(uuid4(), "de-otro")
    )

    await deps.connect().execute(USER, "code-2")

    assert ("revoke", "de-otro") not in deps.gmail.calls
    assert deps.repo.by_user[USER].status is GmailConnectionStatus.ACTIVE


async def test_reconectar_con_la_misma_cuenta_no_revoca_el_grant() -> None:
    # Revocar el token viejo de la misma cuenta mataria tambien el recien emitido.
    deps = _Deps()
    await deps.seed(email="Ana@Gmail.com")

    await deps.connect().execute(USER, "code-2")

    assert [op for op, _ in deps.gmail.calls] == ["exchange_code", "access_token", "watch"]


async def test_reconectar_con_la_misma_cuenta_conserva_el_cursor() -> None:
    # Adoptar el historyId del watch saltaria el correo aun no sincronizado; si el
    # cursor viejo vencio, el 404 de history cae al resync de 7 dias.
    deps = _Deps()
    await deps.seed(email="Ana@Gmail.com", history_id=10, status=GmailConnectionStatus.REVOKED)
    deps.gmail.history_id = 999

    await deps.connect().execute(USER, "code-2")

    stored = deps.repo.by_user[USER]
    assert (stored.history_id, stored.status) == (10, GmailConnectionStatus.ACTIVE)


async def test_reconectar_con_la_misma_cuenta_y_watch_fallido_conserva_el_cursor() -> None:
    deps = _Deps()
    await deps.seed(history_id=10)
    deps.gmail.errors["watch"] = GmailTransientError("watch: 503")

    await deps.connect().execute(USER, "code-2")

    stored = deps.repo.by_user[USER]
    assert (stored.history_id, stored.status) == (10, GmailConnectionStatus.ERROR)
    assert stored.watch_expires_at is None


async def test_reconectar_con_la_misma_cuenta_sin_cursor_usa_el_del_watch() -> None:
    deps = _Deps()
    await deps.seed(history_id=None)
    deps.gmail.history_id = 999

    await deps.connect().execute(USER, "code-2")

    assert deps.repo.by_user[USER].history_id == 999


async def test_reconectar_con_otra_cuenta_no_hereda_el_cursor() -> None:
    deps = _Deps()
    await deps.seed(email="vieja@gmail.com", history_id=10)
    deps.gmail.history_id = 999

    await deps.connect().execute(USER, "code-2")

    assert deps.repo.by_user[USER].history_id == 999


async def test_connect_no_llama_a_google_con_la_transaccion_de_lectura_abierta() -> None:
    deps = _Deps()
    await deps.seed(email="vieja@gmail.com")
    commits_at_google_call: list[int] = []
    original = deps.gmail.access_token

    async def spy(refresh_token: str) -> str:
        commits_at_google_call.append(deps.uow.commits)
        return await original(refresh_token)

    deps.gmail.access_token = spy  # type: ignore[method-assign]

    await deps.connect().execute(USER, "code-2")

    assert commits_at_google_call
    assert all(commits >= 1 for commits in commits_at_google_call)


@pytest.mark.parametrize("previous_status", [None, GmailConnectionStatus.REVOKED])
async def test_connect_sin_scope_de_gmail_revoca_el_grant_nuevo_y_no_guarda(
    previous_status: GmailConnectionStatus | None,
) -> None:
    deps = _Deps()
    if previous_status is not None:
        await deps.seed(status=previous_status)
    before = dict(deps.repo.by_user)
    deps.gmail.scope_granted = False

    with pytest.raises(GmailScopeNotGranted):
        await deps.connect().execute(USER, "code-1")

    assert deps.gmail.calls == [("exchange_code", "code-1"), ("revoke", "refresh-1")]
    assert deps.repo.by_user == before


async def test_connect_sin_scope_con_conexion_activa_no_revoca() -> None:
    # Google revoca el grant completo: revocar mataria la conexion activa del usuario.
    deps = _Deps()
    await deps.seed()
    deps.gmail.scope_granted = False

    with pytest.raises(GmailScopeNotGranted):
        await deps.connect().execute(USER, "code-1")

    assert [op for op, _ in deps.gmail.calls] == ["exchange_code"]
    assert deps.repo.by_user[USER].status is GmailConnectionStatus.ACTIVE


async def test_connect_sin_scope_y_revoke_fallido_igual_lanza_scope_not_granted() -> None:
    deps = _Deps()
    deps.gmail.scope_granted = False
    deps.gmail.errors["revoke"] = GmailTransientError("revoke: 503")

    with pytest.raises(GmailScopeNotGranted):
        await deps.connect().execute(USER, "code-1")


# --- DisconnectGmail ------------------------------------------------------------------


async def test_disconnect_no_llama_a_google_con_la_transaccion_de_lectura_abierta() -> None:
    deps = _Deps()
    await deps.seed()
    commits_at_google_call: list[int] = []
    original = deps.gmail.access_token

    async def spy(refresh_token: str) -> str:
        commits_at_google_call.append(deps.uow.commits)
        return await original(refresh_token)

    deps.gmail.access_token = spy  # type: ignore[method-assign]

    await deps.disconnect().execute(USER)

    assert commits_at_google_call == [1]


async def test_disconnect_detiene_revoca_y_borra() -> None:
    deps = _Deps()
    await deps.seed()

    result = await deps.disconnect().execute(USER)

    assert USER not in deps.repo.by_user
    # Uno cierra la lectura antes de llamar a Google y otro confirma el borrado.
    assert deps.uow.commits == 2
    assert deps.gmail.calls == [
        ("access_token", "refresh-viejo"),
        ("stop", "access-for-refresh-viejo"),
        ("revoke", "refresh-viejo"),
    ]
    assert result.existed is True
    assert result.remote_cleanup is True


@pytest.mark.parametrize("failing", ["access_token", "stop", "revoke"])
async def test_disconnect_borra_aunque_google_falle(failing: str) -> None:
    deps = _Deps()
    await deps.seed()
    deps.gmail.errors[failing] = GmailTransientError(f"{failing}: 503")

    result = await deps.disconnect().execute(USER)

    assert USER not in deps.repo.by_user
    assert deps.uow.commits == 2
    assert result.existed is True
    assert result.remote_cleanup is False
    # El revoke se intenta aunque el stop (o el access token) haya fallado.
    assert ("revoke", "refresh-viejo") in deps.gmail.calls


async def test_disconnect_con_token_indescifrable_borra_sin_llamar_a_google() -> None:
    deps = _Deps()
    await deps.seed(refresh_token_enc=deps.cipher.encrypt(uuid4(), "de-otro-usuario"))

    result = await deps.disconnect().execute(USER)

    assert USER not in deps.repo.by_user
    assert deps.gmail.calls == []
    assert deps.uow.commits == 2
    assert result.remote_cleanup is False


async def test_disconnect_no_borra_una_reconexion_concurrente_con_otra_cuenta() -> None:
    deps = _Deps()
    await deps.seed()
    original_revoke = deps.gmail.revoke

    async def revoke_then_reconnect(refresh_token: str) -> None:
        await original_revoke(refresh_token)
        await deps.seed(email="nueva@gmail.com")  # llega un connect mientras tanto

    deps.gmail.revoke = revoke_then_reconnect  # type: ignore[method-assign]

    result = await deps.disconnect().execute(USER)

    assert result.existed is True
    assert deps.repo.by_user[USER].email == "nueva@gmail.com"


async def test_disconnect_sin_conexion_no_hace_nada() -> None:
    deps = _Deps()

    result = await deps.disconnect().execute(USER)

    assert deps.gmail.calls == []
    assert deps.uow.commits == 1
    assert result.existed is False
    assert result.remote_cleanup is False


# --- GetGmailStatus -------------------------------------------------------------------


async def test_status_sin_conexion_es_disconnected() -> None:
    deps = _Deps()

    view = await deps.status().execute(USER)

    assert view.status == "disconnected"
    assert view.email is None
    assert view.last_sync_at is None
    assert view.watch_expires_at is None


async def test_status_con_conexion_refleja_la_fila() -> None:
    deps = _Deps()
    await deps.seed(status=GmailConnectionStatus.ERROR)

    view = await deps.status().execute(USER)

    assert view.status == "error"
    assert view.email == "ana@gmail.com"
    assert view.last_sync_at == NOW
    assert view.watch_expires_at == NOW


async def test_status_de_otro_usuario_no_ve_la_conexion() -> None:
    deps = _Deps()
    await deps.seed()

    view = await deps.status().execute(uuid4())

    assert view.status == "disconnected"
