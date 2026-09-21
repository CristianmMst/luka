"""Mapa de errores de dominio de ingestion -> `AppError` HTTP (spec 005 §1, controller ruling 3)."""

from finanzia.modules.ingestion.domain.errors import (
    IngestionError,
    InvalidChannel,
    InvalidExternalId,
)
from finanzia.shared.errors import ExceptionMap, InternalError, ValidationAppError

INGESTION_EXCEPTION_MAP: ExceptionMap = {
    InvalidExternalId: lambda e: ValidationAppError(
        message="client_hash invalido", field="items.client_hash"
    ),
    InvalidChannel: lambda e: ValidationAppError(message="channel invalido", field="items.channel"),
    IngestionError: lambda e: InternalError(),
}
