"""Errores de dominio de ingestion (sin dependencias de framework, P3)."""


class IngestionError(Exception):
    """Base de todos los errores de dominio del modulo ingestion."""


class InvalidExternalId(IngestionError):  # noqa: N818 - nombre descriptivo, no de excepcion generica
    """`external_id` no cumple el formato esperado para el canal (spec 006 §4.4)."""


class InvalidChannel(IngestionError):  # noqa: N818
    """El canal recibido no es uno de los soportados (`email`/`notification`/`sms_notification`)."""


class RawMessageNotFound(IngestionError):  # noqa: N818
    """No existe un `raw_message` con el identificador solicitado."""


class GmailError(IngestionError):
    """Base de los fallos al hablar con Google (OAuth o Gmail API, spec 006 §2)."""


class GmailAuthRevoked(GmailError):  # noqa: N818
    """Google respondio `invalid_grant`: el refresh token (o el `serverAuthCode` al
    canjearlo) fue revocado, expiro o es invalido. No se reintenta: la conexion
    pasa a `revoked` y el usuario debe reconectar.
    """


class GmailHistoryExpired(GmailError):  # noqa: N818
    """`history.list` respondio 404: el cursor `startHistoryId` es demasiado viejo;
    toca resync con `messages.list` de los ultimos 7 dias (spec 006 §2.1).
    """


class GmailTransientError(GmailError):
    """Fallo transitorio (timeout, red, 5xx o 429): el llamador puede reintentar."""


class GmailRequestRejected(GmailError):  # noqa: N818
    """Google rechazo la peticion (4xx distinto de los anteriores) o respondio algo
    que no se puede interpretar. Reintentar no lo arregla.
    """


class GmailRefreshTokenMissing(GmailRequestRejected):
    """El canje del `serverAuthCode` no trajo refresh token: Google solo lo entrega
    con acceso offline en el primer consentimiento (o forzando el consentimiento).
    """


class GmailScopeNotGranted(GmailRequestRejected):
    """El canje salio bien pero el `scope` del grant no trae `gmail.readonly`: el
    usuario lo desmarco en la pantalla de consentimiento.
    """


class GmailMessageNotFound(GmailRequestRejected):
    """`messages.get` respondio 404 (o 400 por id invalido): el mensaje se borro
    entre `history.list` y la lectura. El sync lo salta; junto con
    `GmailMessageUnreadable` son los unicos rechazos que no cortan la pasada.
    """


class GmailMessageUnreadable(GmailRequestRejected):
    """`messages.get` respondio 2xx con un cuerpo que no se puede interpretar
    (no JSON, sin `payload`/`internalDate`, base64 roto). Reintentar no lo arregla:
    el sync lo salta para no bloquear el cursor del usuario para siempre.
    """


class InvalidPushEnvelope(IngestionError):  # noqa: N818
    """El cuerpo del push de Pub/Sub no tiene la forma esperada (spec 005 §4)."""


class InvalidPushToken(IngestionError):  # noqa: N818
    """El token OIDC del push falta, no verifica o no es del service account esperado."""


class GmailSyncEnqueueFailed(IngestionError):  # noqa: N818
    """No se pudo encolar el job `sync_gmail` (Redis caido): Pub/Sub debe reintentar."""


class InvalidServerAuthCode(IngestionError):  # noqa: N818
    """El `serverAuthCode` es invalido, expiro o ya se uso (`invalid_grant` al canjear)."""


class GmailTokenUndecryptable(IngestionError):  # noqa: N818
    """El refresh token guardado no descifra: llave distinta, otro usuario o dato alterado."""


__all__ = [
    "GmailAuthRevoked",
    "GmailError",
    "GmailHistoryExpired",
    "GmailMessageNotFound",
    "GmailMessageUnreadable",
    "GmailRefreshTokenMissing",
    "GmailRequestRejected",
    "GmailScopeNotGranted",
    "GmailSyncEnqueueFailed",
    "GmailTokenUndecryptable",
    "GmailTransientError",
    "IngestionError",
    "InvalidChannel",
    "InvalidExternalId",
    "InvalidPushEnvelope",
    "InvalidPushToken",
    "InvalidServerAuthCode",
    "RawMessageNotFound",
]
