"""Mapa de errores de dominio de ingestion -> `AppError` HTTP (spec 005 §1, controller ruling 3).

Los mensajes son fijos: nunca incluyen el codigo, el token ni el detalle de Google.
Starlette elige el handler de la clase mas especifica (MRO), asi que
`IngestionError` solo atrapa lo que no tenga una entrada propia.
"""

from finanzia.modules.ingestion.domain.errors import (
    GmailRefreshTokenMissing,
    GmailScopeNotGranted,
    GmailSyncEnqueueFailed,
    GmailTransientError,
    IngestionError,
    InvalidChannel,
    InvalidExternalId,
    InvalidPushToken,
    InvalidServerAuthCode,
)
from finanzia.shared.errors import (
    ExceptionMap,
    ForbiddenError,
    InternalError,
    UpstreamUnavailableError,
    ValidationAppError,
)

INGESTION_EXCEPTION_MAP: ExceptionMap = {
    InvalidExternalId: lambda e: ValidationAppError(
        message="client_hash invalido", field="items.client_hash"
    ),
    InvalidChannel: lambda e: ValidationAppError(message="channel invalido", field="items.channel"),
    InvalidServerAuthCode: lambda e: ValidationAppError(
        message="server_auth_code invalido, vencido o ya usado", field="server_auth_code"
    ),
    GmailRefreshTokenMissing: lambda e: ValidationAppError(
        message=(
            "Google no entrego refresh token: la app debe pedir acceso offline "
            "y forzar el consentimiento"
        ),
        field="server_auth_code",
    ),
    GmailScopeNotGranted: lambda e: ValidationAppError(
        message="permiso de Gmail no concedido: la app debe pedir gmail.readonly",
        field="server_auth_code",
    ),
    GmailTransientError: lambda e: UpstreamUnavailableError(),
    # Webhook push (spec 005 §4): 403 sin distinguir el motivo; 503 para que Pub/Sub reintente.
    InvalidPushToken: lambda e: ForbiddenError(message="token de push invalido"),
    GmailSyncEnqueueFailed: lambda e: UpstreamUnavailableError(),
    IngestionError: lambda e: InternalError(),
}
