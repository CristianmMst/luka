"""Ports (interfaces) que la capa application de ledger expone a infrastructure."""

from __future__ import annotations

from collections.abc import Sequence
from datetime import datetime
from decimal import Decimal
from typing import Protocol
from uuid import UUID

from finanzia.modules.ledger.application.dto import Cursor, Filters
from finanzia.modules.ledger.domain.entities import (
    Category,
    LinkedAccount,
    MerchantRule,
    Transaction,
    TransactionSource,
)
from finanzia.modules.ledger.domain.enums import Bank, Direction, FiscalTag

# --- Transacciones -----------------------------------------------------------------


class TransactionRepositoryPort(Protocol):
    """Persistencia de transacciones (spec 004 SS2.5, SS3, SS4)."""

    async def insert_if_absent(self, tx: Transaction) -> UUID | None:
        """Inserta `tx`; `None` si `(user_id, dedupe_key)` ya existia (spec 004 SS3)."""
        ...

    async def find_by_dedupe_keys(self, user_id: UUID, keys: Sequence[str]) -> list[Transaction]:
        """Transacciones del usuario cuyo `dedupe_key` este en `keys`."""
        ...

    async def get(self, user_id: UUID, id: UUID) -> Transaction | None:
        """Transaccion propia por id, o `None` si no existe o es de otro usuario."""
        ...

    async def get_many(self, user_id: UUID, ids: Sequence[UUID]) -> list[Transaction]:
        """Transacciones propias cuyo id este en `ids`."""
        ...

    async def list(
        self, user_id: UUID, filters: Filters, cursor: Cursor | None, limit: int
    ) -> list[Transaction]:
        """Hasta `limit` filas ordenadas por keyset; el caso de uso pide `limit + 1`
        para detectar si hay una pagina siguiente (spec 005 SS1).
        """
        ...

    async def update(self, tx: Transaction) -> None:
        """Reemplaza el estado persistido de `tx` (misma `id`)."""
        ...

    async def delete(self, user_id: UUID, id: UUID) -> None:
        """Borra la transaccion propia `id`, si existe."""
        ...

    async def find_transfer_candidates(
        self,
        user_id: UUID,
        direction: Direction,
        amount: Decimal,
        since: datetime,
        until: datetime,
    ) -> list[Transaction]:
        """Filtro grueso (usuario/direccion/monto/ventana); el fino lo hace el dominio
        (`transfers.find_transfer_match`, spec 004 SS4).
        """
        ...

    async def reassign_category(
        self,
        user_id: UUID,
        from_category_id: UUID,
        to_category_id: UUID,
        fiscal_tag: FiscalTag,
        now: datetime,
    ) -> int:
        """Reasigna todas las transacciones de `from_category_id` a `to_category_id`.

        Devuelve la cantidad de filas afectadas (spec 005 SS7, borrado de categoria).
        """
        ...


class TransactionSourceRepositoryPort(Protocol):
    """Persistencia de fuentes crudas (email/notificacion/SMS/manual/NFC)."""

    async def attach(self, source: TransactionSource) -> bool:
        """Adjunta `source`; `True` si se inserto, `False` si ya existia (idempotente
        sobre `(transaction_id, raw_message_id)` cuando `raw_message_id` no es `None`).
        """
        ...

    async def list_for(self, transaction_id: UUID) -> list[TransactionSource]:
        """Todas las fuentes adjuntas a una transaccion."""
        ...


# --- Categorias ----------------------------------------------------------------------


class CategoryRepositoryPort(Protocol):
    """Persistencia de categorias del sistema y propias del usuario (spec 004 SS2.8)."""

    async def get_visible(self, user_id: UUID, category_id: UUID) -> Category | None:
        """Categoria visible para `user_id`: del sistema o propia; `None` si no aplica."""
        ...

    async def list_visible(self, user_id: UUID) -> list[Category]:
        """Todas las categorias visibles para `user_id` (sistema + propias)."""
        ...

    async def get_system_by_slug(self, slug: str) -> Category | None:
        """Categoria del sistema por `slug`, o `None` si no existe."""
        ...

    async def exists_name(self, user_id: UUID, name: str) -> bool:
        """`True` si el usuario ya tiene una categoria propia con ese `name`."""
        ...

    async def add(self, category: Category) -> None: ...

    async def update(self, category: Category) -> None: ...

    async def delete(self, user_id: UUID, id: UUID) -> None: ...


# --- Cuentas vinculadas ----------------------------------------------------------------


class LinkedAccountRepositoryPort(Protocol):
    """Persistencia de cuentas/tarjetas vinculadas por el usuario (spec 004 SS2.4)."""

    async def get(self, user_id: UUID, id: UUID) -> LinkedAccount | None: ...

    async def find_by_bank_last4(
        self, user_id: UUID, bank: Bank, last4: str
    ) -> LinkedAccount | None: ...

    async def list(self, user_id: UUID) -> list[LinkedAccount]: ...

    async def exists(self, user_id: UUID, bank: Bank, last4: str | None) -> bool:
        """`True` si ya existe una cuenta propia con el mismo `(bank, last4)`."""
        ...

    async def add(self, account: LinkedAccount) -> None: ...

    async def update(self, account: LinkedAccount) -> None: ...

    async def delete(self, user_id: UUID, id: UUID) -> None: ...


# --- Reglas de comercio (spec 006 SS4.3) -------------------------------------------------


class MerchantRuleRepositoryPort(Protocol):
    """Reglas aprendidas de comercio -> categoria (`(user_id, merchant_pattern)`)."""

    async def upsert(self, rule: MerchantRule) -> None:
        """Inserta o reemplaza la regla; la ultima correccion gana."""
        ...

    async def list_for_user(self, user_id: UUID) -> list[MerchantRule]: ...

    async def delete_for_category(self, user_id: UUID, category_id: UUID) -> None: ...


# --- Infraestructura transversal ------------------------------------------------------


class EventPublisherPort(Protocol):
    """Publicacion de eventos de dominio (`finanzia.modules.ledger.events`)."""

    async def publish(self, event: object) -> None: ...


class ClockPort(Protocol):
    """Fuente de tiempo inyectable (siempre aware, UTC)."""

    def now(self) -> datetime: ...


class IdGeneratorPort(Protocol):
    """Generacion de identificadores y de aleatoriedad para claves manuales."""

    def new_id(self) -> UUID: ...

    def random_hex(self, n_bytes: int) -> str:
        """Cadena hexadecimal aleatoria de `n_bytes` bytes (spec 004 SS3, clave manual)."""
        ...


class UnitOfWorkPort(Protocol):
    """Confirma los cambios acumulados en la unidad de trabajo actual."""

    async def commit(self) -> None: ...


__all__ = [
    "CategoryRepositoryPort",
    "ClockPort",
    "EventPublisherPort",
    "IdGeneratorPort",
    "LinkedAccountRepositoryPort",
    "MerchantRuleRepositoryPort",
    "TransactionRepositoryPort",
    "TransactionSourceRepositoryPort",
    "UnitOfWorkPort",
]
