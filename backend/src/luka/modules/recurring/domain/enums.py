"""Enums de dominio de recurring (spec 004 SS2.13). Solo stdlib (P3)."""

from enum import StrEnum


class OccurrenceStatus(StrEnum):
    """Estado de una ocurrencia mensual de un gasto fijo (spec 011 SS2)."""

    PENDING = "pending"
    PAID = "paid"
    SKIPPED = "skipped"


class MatchedBy(StrEnum):
    """Quien emparejo el pago: el matcher o el usuario (spec 011 SS4.1)."""

    AUTO = "auto"
    MANUAL = "manual"
