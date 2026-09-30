"""Mapa de errores de dominio de notifications -> `AppError` HTTP (spec 005 SS1)."""

from luka.modules.notifications.domain.errors import InvalidPushToken
from luka.shared.errors import ExceptionMap, ValidationAppError

NOTIFICATIONS_EXCEPTION_MAP: ExceptionMap = {
    InvalidPushToken: lambda e: ValidationAppError(message="Token invalido", field="token"),
}
