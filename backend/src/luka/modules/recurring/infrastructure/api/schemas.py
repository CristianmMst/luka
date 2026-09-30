"""Schemas Pydantic de la API de recurring (spec 005 SS10).

Los requests usan `extra="forbid"`; los rangos simples (tolerancia, dia, aviso)
los valida Pydantic y el dominio (`validate_expense_fields`) es la fuente de
verdad del resto (nombre, keyword, monto > 0).
"""

from datetime import date, datetime
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

AmountStr = Annotated[str, Field(pattern=r"^\d{1,12}(\.\d{1,2})?$")]
Tolerance = Annotated[int, Field(ge=0, le=50)]
DayOfMonth = Annotated[int, Field(ge=1, le=31)]
RemindDays = Literal[1, 2]


class CreateRecurringExpenseRequest(BaseModel):
    """Body de `POST /recurring-expenses`."""

    model_config = ConfigDict(extra="forbid")

    name: str = Field(max_length=200)
    merchant_keyword: str = Field(max_length=200)
    expected_amount: AmountStr
    day_of_month: DayOfMonth
    amount_tolerance_pct: Tolerance = 10
    remind_days_before: RemindDays = 1
    category_id: UUID | None = None
    account_id: UUID | None = None


class PatchRecurringExpenseRequest(BaseModel):
    """Body de `PATCH /recurring-expenses/{id}`; `model_fields_set` dice que se envio."""

    model_config = ConfigDict(extra="forbid")

    name: str | None = Field(default=None, max_length=200)
    merchant_keyword: str | None = Field(default=None, max_length=200)
    expected_amount: AmountStr | None = None
    day_of_month: DayOfMonth | None = None
    amount_tolerance_pct: Tolerance | None = None
    remind_days_before: RemindDays | None = None
    category_id: UUID | None = None
    account_id: UUID | None = None
    active: bool | None = None


class MarkPaidRequest(BaseModel):
    """Body de `POST /recurring-occurrences/{id}/mark-paid`."""

    model_config = ConfigDict(extra="forbid")

    transaction_id: UUID | None = None


class RecurringExpenseResponse(BaseModel):
    """Un gasto fijo propio."""

    id: UUID
    name: str
    merchant_keyword: str
    expected_amount: str
    amount_tolerance_pct: int
    day_of_month: int
    category_id: UUID | None
    account_id: UUID | None
    remind_days_before: int
    active: bool
    created_at: datetime
    updated_at: datetime


class OccurrenceExpenseResponse(BaseModel):
    """El gasto fijo embebido en una ocurrencia."""

    id: UUID
    name: str
    merchant_keyword: str
    expected_amount: str
    category_id: UUID | None
    active: bool


class OccurrenceTransactionResponse(BaseModel):
    """La transaccion que pago la ocurrencia, resumida."""

    id: UUID
    merchant: str | None
    amount: str
    occurred_at: datetime


class OccurrenceResponse(BaseModel):
    """Una ocurrencia con su gasto fijo y, si esta pagada, su transaccion."""

    id: UUID
    recurring_expense: OccurrenceExpenseResponse
    period: str
    due_date: date
    status: str
    matched_by: str | None
    paid_at: datetime | None
    reminded_at: datetime | None
    transaction: OccurrenceTransactionResponse | None
