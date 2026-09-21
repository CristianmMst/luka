"""Errores de dominio de ingestion (sin dependencias de framework, P3)."""


class IngestionError(Exception):
    """Base de todos los errores de dominio del modulo ingestion."""


class InvalidExternalId(IngestionError):  # noqa: N818 - nombre descriptivo, no de excepcion generica
    """`external_id` no cumple el formato esperado para el canal (spec 006 §4.4)."""


class InvalidChannel(IngestionError):  # noqa: N818
    """El canal recibido no es uno de los soportados (`email`/`notification`/`sms_notification`)."""


class RawMessageNotFound(IngestionError):  # noqa: N818
    """No existe un `raw_message` con el identificador solicitado."""


__all__ = ["IngestionError", "InvalidChannel", "InvalidExternalId", "RawMessageNotFound"]
