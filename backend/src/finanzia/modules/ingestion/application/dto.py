"""DTOs de entrada/salida de los casos de uso de ingestion (frozen, stdlib puro)."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus

# --- Entrada -------------------------------------------------------------------------


@dataclass(frozen=True, slots=True)
class RawMessageInput:
    """Comando de entrada de `IngestRawMessage` (spec 006 §2.2-2.3, §3.2)."""

    user_id: UUID
    channel: Channel
    external_id: str
    sender: str
    title: str | None
    text: str
    received_at: datetime


@dataclass(frozen=True, slots=True)
class NotificationItemInput:
    """Un item de un batch de `POST /v1/ingest/notifications` (spec 006 §3.2, F4.3)."""

    package: str
    channel: Channel
    posted_at: datetime
    title: str | None
    text: str
    client_hash: str


# --- Resultado de `IngestRawMessage` (spec 006 §4.4, D9) ----------------------------


@dataclass(frozen=True, slots=True)
class Accepted:
    """El mensaje se persistio como `pending` y se publico `RawMessageReceived`.

    `bank` es el banco resuelto por el filtro de remitente/paquete al ingerir; se
    expone aqui (ademas de en la fila) para que `infrastructure` pueda emitir
    metricas `parsing_metric` por banco/canal (spec 006 §6) sin una SELECT extra.
    """

    raw_message_id: UUID
    bank: str | None


@dataclass(frozen=True, slots=True)
class Duplicate:
    """`(user_id, channel, external_id)` ya existia (idempotencia de ingesta, AC-5.2).

    `republished=True` cuando la fila existente seguia `pending` y se volvio a
    publicar `RawMessageReceived` (D9, mitiga la falta de outbox). `bank` es el de
    la fila ya existente (spec 006 §6, metricas por banco/canal).
    """

    raw_message_id: UUID
    republished: bool
    bank: str | None


@dataclass(frozen=True, slots=True)
class Discarded:
    """El remitente/paquete no esta soportado: nada se persistio (AC-2.4).

    `reason` es `"unsupported_sender"` (email) o `"unsupported_package"`
    (notification/sms_notification).
    """

    reason: str


IngestOutcome = Accepted | Duplicate | Discarded


@dataclass(frozen=True, slots=True)
class BatchResult:
    """Resultado agregado de `IngestNotificationsBatch`."""

    accepted: int
    duplicates: int
    discarded: int


@dataclass(frozen=True, slots=True)
class RequeueSummary:
    """Resultado de una corrida de `RequeuePendingRawMessages` (riesgo 4 / D9).

    `exhausted` son las filas que superaron el maximo de republicaciones y
    pasaron a `failed`: dejan de estar `pending`, asi que el cron ya no las toma.
    """

    requeued: int
    exhausted: int


# --- Lectura (fachada, Fase 3) -------------------------------------------------------


@dataclass(frozen=True, slots=True)
class RawMessageView:
    """Proyeccion de solo lectura de un `raw_message`, expuesta via `public.py`."""

    id: UUID
    user_id: UUID
    channel: Channel
    bank: str | None
    sender: str
    body: str | None
    status: RawMessageStatus
    received_at: datetime


# --- Puertos: allowlists (D6) ---------------------------------------------------------


@dataclass(frozen=True, slots=True)
class BankDecision:
    """Resultado de `SenderPolicyPort.bank_for_notification` (spec 006 §3.2)."""

    accepted: bool
    bank: str | None


# --- Conexion Gmail (F3.3, spec 005 §3) -----------------------------------------------

#: Estado de `GET /v1/gmail/status` cuando el usuario no tiene fila en `gmail_connections`.
GMAIL_DISCONNECTED = "disconnected"


@dataclass(frozen=True, slots=True)
class GmailConnectionView:
    """Estado visible de la conexion Gmail de un usuario; nunca lleva el token.

    `status` es `active`/`revoked`/`error` (`GmailConnectionStatus`) o
    `disconnected` si no hay conexion.
    """

    status: str
    email: str | None
    last_sync_at: datetime | None
    watch_expires_at: datetime | None


@dataclass(frozen=True, slots=True)
class RenewWatchesSummary:
    """Resultado de una corrida de `RenewGmailWatches` (cron diario, F3.5, spec 006 §2.1).

    Solo contadores (nunca el email de la cuenta ni el refresh token, P1/P6).
    `renewed` son watches renovados con exito; `revoked`/`errored` las conexiones
    que pasaron a ese estado durante la corrida (un `GmailAuthRevoked` revoca, el
    resto de fallos de Gmail o un token indescifrable marcan error).
    """

    renewed: int = 0
    revoked: int = 0
    errored: int = 0


@dataclass(frozen=True, slots=True)
class DisconnectResult:
    """Resultado de `DisconnectGmail`: si habia conexion y si Google confirmo stop/revoke."""

    existed: bool
    remote_cleanup: bool


@dataclass(frozen=True, slots=True)
class GmailSyncResult:
    """Resultado de una pasada de `SyncGmail` (solo contadores, nunca datos del correo).

    `status`: `synced`, `up_to_date` (el aviso ya estaba cubierto por el cursor),
    `no_connection`, `inactive` (conexion `revoked`/`error`), `revoked` (Google
    respondio `invalid_grant` en esta pasada), `undecryptable` (el token guardado
    no descifra; la conexion pasa a `error`) o `error` (rechazo permanente de
    Google en `access_token`/`history.list`, p. ej. `invalid_client`; la conexion
    tambien pasa a `error`). `skipped` son ids que Gmail ya no devuelve (borrados
    entre `history.list` y `messages.get`).
    """

    status: str
    resync: bool = False
    fetched: int = 0
    accepted: int = 0
    duplicates: int = 0
    discarded: int = 0
    skipped: int = 0


__all__ = [
    "GMAIL_DISCONNECTED",
    "Accepted",
    "BankDecision",
    "BatchResult",
    "Discarded",
    "DisconnectResult",
    "Duplicate",
    "GmailConnectionView",
    "GmailSyncResult",
    "IngestOutcome",
    "NotificationItemInput",
    "RawMessageInput",
    "RawMessageView",
    "RenewWatchesSummary",
    "RequeueSummary",
]
