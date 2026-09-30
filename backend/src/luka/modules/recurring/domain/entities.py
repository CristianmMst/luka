"""Entidades de recurring: gasto fijo y su ocurrencia mensual (spec 011 SS2, 004 SS2.12-2.13)."""

from __future__ import annotations

import unicodedata
from dataclasses import dataclass
from datetime import date, datetime
from decimal import ROUND_HALF_UP, Decimal, InvalidOperation
from uuid import UUID

from luka.modules.recurring.domain.enums import MatchedBy, OccurrenceStatus
from luka.modules.recurring.domain.errors import InvalidRecurringExpense

NAME_MAX = 60
KEYWORD_MIN = 2
KEYWORD_MAX = 40
TOLERANCE_MAX = 50
#: Monto exacto por defecto: el usuario solo pone nombre, monto y dia (spec 011 SS4).
DEFAULT_TOLERANCE_PCT = 0
DEFAULT_REMIND_DAYS_BEFORE = 1
REMIND_DAYS_CHOICES = (1, 2)
_CENTS = Decimal("0.01")


def normalize_text(value: str) -> str:
    """Sin tildes, en mayusculas y sin puntuacion; espacios colapsados (spec 011 SS4).

    Copia local de la normalizacion del matcher de titular (spec 004 SS4.1): R4
    impide importar `ledger.domain`.
    """
    decomposed = unicodedata.normalize("NFKD", value)
    no_marks = "".join(ch for ch in decomposed if not unicodedata.combining(ch))
    cleaned = "".join(ch if ch.isalnum() else " " for ch in no_marks.upper())
    return " ".join(cleaned.split())


#: Palabras del nombre que no identifican al comercio ("Pago de Spotify" -> SPOTIFY).
_STOPWORDS = frozenset(
    {"DE", "DEL", "LA", "EL", "LOS", "LAS", "Y", "EN", "PAGO", "PLAN", "MES", "CUOTA", "SERVICIO"}
)
#: Una palabra corta ("TV") coincide con demasiados comercios.
_TOKEN_MIN = 3


def keyword_tokens(keyword: str) -> tuple[str, ...]:
    """Palabras normalizadas de la keyword que sirven para reconocer el comercio."""
    return tuple(
        word
        for word in normalize_text(keyword).split()
        if len(word) >= _TOKEN_MIN and word not in _STOPWORDS
    )


def quantize_amount(value: Decimal | int | str) -> Decimal:
    """Monto a 2 decimales (ROUND_HALF_UP); debe ser finito y > 0."""
    try:
        amount = Decimal(value).quantize(_CENTS, rounding=ROUND_HALF_UP)
    except (InvalidOperation, ValueError) as exc:
        raise InvalidRecurringExpense("expected_amount") from exc
    if not amount.is_finite() or amount <= 0:
        raise InvalidRecurringExpense("expected_amount")
    return amount


@dataclass(frozen=True, slots=True)
class RecurringExpense:
    """Gasto fijo mensual del usuario (spec 004 SS2.12)."""

    id: UUID
    user_id: UUID
    name: str
    merchant_keyword: str
    expected_amount: Decimal
    amount_tolerance_pct: int
    day_of_month: int
    category_id: UUID | None
    account_id: UUID | None
    remind_days_before: int
    active: bool
    created_at: datetime
    updated_at: datetime

    @property
    def keyword_tokens(self) -> tuple[str, ...]:
        return keyword_tokens(self.merchant_keyword)


def validate_expense_fields(  # noqa: PLR0913 - un parametro por campo editable
    *,
    name: str,
    merchant_keyword: str,
    expected_amount: Decimal | int | str,
    amount_tolerance_pct: int,
    day_of_month: int,
    remind_days_before: int,
    keyword_field: str = "merchant_keyword",
) -> tuple[str, str, Decimal]:
    """Valida los campos editables (spec 005 SS10) y devuelve nombre, keyword y monto limpios.

    Lanza `InvalidRecurringExpense(field)` con el primer campo invalido.
    """
    clean_name = " ".join(name.split())
    if not 1 <= len(clean_name) <= NAME_MAX:
        raise InvalidRecurringExpense("name")
    clean_keyword = " ".join(merchant_keyword.split())
    alnum = sum(1 for ch in normalize_text(clean_keyword) if ch.isalnum())
    if not KEYWORD_MIN <= len(clean_keyword) <= KEYWORD_MAX or alnum < KEYWORD_MIN:
        # Sin keyword propia se usa el nombre: el error se reporta en `name`.
        raise InvalidRecurringExpense(keyword_field)
    amount = quantize_amount(expected_amount)
    if not 0 <= amount_tolerance_pct <= TOLERANCE_MAX:
        raise InvalidRecurringExpense("amount_tolerance_pct")
    if not 1 <= day_of_month <= 31:  # noqa: PLR2004 - dias del mes
        raise InvalidRecurringExpense("day_of_month")
    if remind_days_before not in REMIND_DAYS_CHOICES:
        raise InvalidRecurringExpense("remind_days_before")
    return clean_name, clean_keyword, amount


@dataclass(frozen=True, slots=True)
class Occurrence:
    """Un gasto fijo en un mes concreto (spec 004 SS2.13)."""

    id: UUID
    user_id: UUID
    recurring_expense_id: UUID
    period: date
    due_date: date
    status: OccurrenceStatus
    transaction_id: UUID | None
    matched_by: MatchedBy | None
    paid_at: datetime | None
    reminded_at: datetime | None
