"""Ports (interfaces) que la capa application de recurring expone a infrastructure."""

from __future__ import annotations

from collections.abc import Collection, Sequence
from datetime import date, datetime
from typing import Protocol
from uuid import UUID

from luka.modules.recurring.application.dto import TransactionSummary
from luka.modules.recurring.domain.entities import Occurrence, RecurringExpense
from luka.modules.recurring.domain.matcher import TxCandidate


class RecurringExpenseRepositoryPort(Protocol):
    """Persistencia de `recurring_expenses` (spec 004 SS2.12); todo filtra por usuario."""

    async def get(self, user_id: UUID, id: UUID) -> RecurringExpense | None: ...

    async def list(self, user_id: UUID) -> list[RecurringExpense]: ...

    async def list_active(self) -> list[RecurringExpense]: ...

    async def add(self, expense: RecurringExpense) -> None: ...

    async def update(self, expense: RecurringExpense) -> None: ...

    async def delete(self, user_id: UUID, id: UUID) -> None: ...


class OccurrenceRepositoryPort(Protocol):
    """Persistencia de `recurring_occurrences` (spec 004 SS2.13)."""

    async def add_if_absent(self, occurrence: Occurrence) -> bool:
        """Inserta si no existe `(recurring_expense_id, period)`; `True` si inserto."""
        ...

    async def get(self, user_id: UUID, id: UUID) -> Occurrence | None: ...

    async def list_range(
        self, user_id: UUID, period_from: date, period_to: date
    ) -> list[Occurrence]: ...

    async def list_for_user(self, user_id: UUID) -> list[Occurrence]: ...

    async def pending_for_expense(self, expense_id: UUID) -> list[Occurrence]: ...

    async def candidates(
        self, user_id: UUID, due_from: date, due_to: date
    ) -> list[tuple[Occurrence, RecurringExpense]]:
        """Ocurrencias `pending` de gastos activos del usuario con `due_date` en el rango."""
        ...

    async def claim_auto(self, occurrence_id: UUID, transaction_id: UUID, now: datetime) -> bool:
        """`pending` -> `paid` (auto) si sigue `pending` y la transaccion no paga otra."""
        ...

    async def save(self, occurrence: Occurrence) -> None:
        """Reemplaza estado, transaccion, `matched_by`, `paid_at` y `due_date`."""
        ...

    async def find_by_transaction(
        self, user_id: UUID, transaction_id: UUID
    ) -> Occurrence | None: ...

    async def delete_pending_after(self, expense_id: UUID, period: date) -> None:
        """Borra las `pending` del gasto con `period` posterior a `period`."""
        ...

    async def reminder_candidates(
        self, due_from: date, due_to: date
    ) -> list[tuple[Occurrence, RecurringExpense]]:
        """`pending` sin aviso de gastos activos con `due_date` en el rango (todos los usuarios)."""
        ...

    async def mark_reminded(self, occurrence_id: UUID, now: datetime) -> bool:
        """Pone `reminded_at` si seguia nulo; `True` si lo marco."""
        ...


class RejectionRepositoryPort(Protocol):
    """Pares (ocurrencia, transaccion) desemparejados por el usuario (spec 004 SS2.14)."""

    async def add(self, occurrence_id: UUID, transaction_id: UUID) -> None: ...

    async def rejected_occurrences(
        self, transaction_id: UUID, occurrence_ids: Collection[UUID]
    ) -> set[UUID]: ...


class LedgerPort(Protocol):
    """Lo que recurring lee del ledger via `ledger.public` (R4)."""

    async def get_transaction(self, user_id: UUID, id: UUID) -> TxCandidate | None: ...

    async def expenses_in_window(
        self, user_id: UUID, start: datetime, end: datetime
    ) -> list[TxCandidate]: ...

    async def summaries(
        self, user_id: UUID, ids: Sequence[UUID]
    ) -> dict[UUID, TransactionSummary]: ...

    async def category_visible(self, user_id: UUID, id: UUID) -> bool: ...

    async def account_owned(self, user_id: UUID, id: UUID) -> bool: ...


class EventPublisherPort(Protocol):
    """Publica eventos de recurring en el bus (despues del commit)."""

    async def publish(self, event: object) -> None: ...


class ClockPort(Protocol):
    """Reloj inyectado (nunca `datetime.now()` directo)."""

    def now(self) -> datetime: ...


class IdGeneratorPort(Protocol):
    """Generador de ids."""

    def new_id(self) -> UUID: ...


class UnitOfWorkPort(Protocol):
    """Confirma la transaccion de base de datos en curso."""

    async def commit(self) -> None: ...
