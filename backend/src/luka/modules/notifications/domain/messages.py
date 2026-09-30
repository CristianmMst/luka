"""Texto del recordatorio de pago (spec 011 SS5). Logica pura, solo stdlib (P3)."""

from __future__ import annotations

from datetime import date
from decimal import ROUND_HALF_UP, Decimal
from uuid import UUID

from luka.modules.notifications.domain.entities import PushMessage

_MONTHS = (
    "enero",
    "febrero",
    "marzo",
    "abril",
    "mayo",
    "junio",
    "julio",
    "agosto",
    "septiembre",
    "octubre",
    "noviembre",
    "diciembre",
)
#: Canal Android de los recordatorios (spec 008 SS4.3).
REMINDER_CHANNEL_ID = "recordatorios_pagos"
REMINDER_DATA_TYPE = "recurring_due"


def format_cop(amount: Decimal) -> str:
    """Pesos con puntos de miles, como la app: `$16.900`; con centavos, `$16.900,50`."""
    cents = int((amount * 100).quantize(Decimal(1), rounding=ROUND_HALF_UP))
    pesos, rest = divmod(abs(cents), 100)
    grouped = f"{pesos:,}".replace(",", ".")
    text = f"${grouped}" if rest == 0 else f"${grouped},{rest:02d}"
    return f"-{text}" if cents < 0 else text


def spanish_day(day: date) -> str:
    """`date(2026, 10, 22)` -> `22 de octubre`."""
    return f"{day.day} de {_MONTHS[day.month - 1]}"


def due_reminder_message(
    *,
    occurrence_id: UUID,
    name: str,
    amount: Decimal,
    due_date: date,
    today: date,
) -> PushMessage:
    """Recordatorio de un gasto fijo pendiente (spec 011 SS5).

    Falta un dia: "Mañana, 22 de octubre, …"; dos: "Pasado mañana, 22 de octubre, …";
    vence hoy (aviso atrasado): "Hoy …"; en otro caso (7 dias): "El 22 de octubre …".
    """
    money = format_cop(amount)
    days_left = (due_date - today).days
    if days_left <= 0:
        when = "Hoy"
    elif days_left == 1:
        when = f"Mañana, {spanish_day(due_date)},"
    elif days_left == 2:  # noqa: PLR2004 - aviso de 2 dias (spec 011 SS5)
        when = f"Pasado mañana, {spanish_day(due_date)},"
    else:
        when = f"El {spanish_day(due_date)}"
    return PushMessage(
        title=f"Se acerca tu pago de {name}",
        body=f"{when} se te descontarán {money} de tu cuenta.",
        data={"type": REMINDER_DATA_TYPE, "occurrence_id": str(occurrence_id)},
    )
