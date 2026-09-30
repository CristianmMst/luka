"""Enums de dominio de ingestion (stdlib puro, P3)."""

from enum import StrEnum


class Channel(StrEnum):
    """Canales de captura soportados (spec 006 §1)."""

    EMAIL = "email"
    NOTIFICATION = "notification"
    SMS_NOTIFICATION = "sms_notification"


class RawMessageStatus(StrEnum):
    """Estados de un `raw_message` (spec 004 §2.7)."""

    PENDING = "pending"
    PARSED = "parsed"
    FAILED = "failed"
    DISCARDED = "discarded"
    REVIEWED = "reviewed"


class GmailConnectionStatus(StrEnum):
    """Estados de una `gmail_connections` (spec 004 §2.3, F3.2)."""

    ACTIVE = "active"
    REVOKED = "revoked"
    ERROR = "error"


__all__ = ["Channel", "GmailConnectionStatus", "RawMessageStatus"]
