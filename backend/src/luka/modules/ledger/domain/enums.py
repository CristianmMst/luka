"""Enums de dominio de ledger (spec 004 SS2.4-2.9, spec 007 SS2). Solo stdlib (P3)."""

from enum import StrEnum


class Bank(StrEnum):
    """Bancos soportados (spec 001) + `other` para el resto."""

    BANCOLOMBIA = "bancolombia"
    NEQUI = "nequi"
    DAVIVIENDA = "davivienda"
    DAVIPLATA = "daviplata"
    BBVA = "bbva"
    BANCO_BOGOTA = "banco_bogota"
    OTHER = "other"


class AccountKind(StrEnum):
    """Tipo de cuenta/tarjeta vinculada (spec 004 SS2.4)."""

    SAVINGS = "savings"
    CHECKING = "checking"
    CREDIT_CARD = "credit_card"
    WALLET = "wallet"


class Direction(StrEnum):
    """Sentido del movimiento (spec 004 SS2.5)."""

    DEBIT = "debit"
    CREDIT = "credit"


class Kind(StrEnum):
    """Naturaleza de la transaccion (spec 004 SS2.5)."""

    EXPENSE = "expense"
    INCOME = "income"
    TRANSFER = "transfer"


class Channel(StrEnum):
    """Canal de captura de una fuente de transaccion (spec 004 SS2.6)."""

    EMAIL = "email"
    NOTIFICATION = "notification"
    SMS_NOTIFICATION = "sms_notification"
    MANUAL = "manual"


class FiscalTag(StrEnum):
    """Etiquetas fiscales cerradas (spec 007 SS2). Toda categoria lleva exactamente una."""

    INGRESO_LABORAL = "ingreso_laboral"
    INGRESO_HONORARIOS = "ingreso_honorarios"
    INGRESO_CAPITAL = "ingreso_capital"
    INGRESO_NO_LABORAL = "ingreso_no_laboral"
    INGRESO_PENSION = "ingreso_pension"
    DEDUCIBLE_SALUD = "deducible_salud"
    DEDUCIBLE_VIVIENDA = "deducible_vivienda"
    APORTE_PENSION_VOLUNTARIA = "aporte_pension_voluntaria"
    APORTE_AFC = "aporte_afc"
    APORTE_OBLIGATORIO = "aporte_obligatorio"
    DONACION = "donacion"
    NO_DEDUCIBLE = "no_deducible"
    TRANSFERENCIA = "transferencia"
