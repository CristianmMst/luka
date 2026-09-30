"""Ports (interfaces) que la capa application de ledger expone a infrastructure."""

from __future__ import annotations

from collections.abc import Collection, Sequence
from datetime import datetime
from decimal import Decimal
from typing import Protocol
from uuid import UUID

from luka.modules.ledger.application.dto import Cursor, Filters, ReviewSourceView
from luka.modules.ledger.domain.entities import (
    Category,
    LinkedAccount,
    MerchantRule,
    Transaction,
    TransactionSource,
)
from luka.modules.ledger.domain.enums import Bank, Channel, Direction, FiscalTag
from luka.modules.ledger.domain.review import ReviewItem, ReviewResolution

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

    async def find_non_transfers_by_parsed_by(
        self, parsed_by: Collection[str], user_id: UUID | None
    ) -> list[Transaction]:
        """Las que no son `transfer`, con `parsed_by` en `parsed_by`, de `user_id`
        (o de todos si es `None`). Para reclasificar transferencias propias
        (spec 004 SS4.1)."""
        ...

    async def touch(self, user_id: UUID, id: UUID, at: datetime) -> None:
        """Pone `updated_at = at` en la transaccion propia `id` sin tocar otra columna.

        Lo usa el camino de dedupe al adjuntar una fuente: reescribir la fila completa
        con un snapshot leido sin lock pisaria un PATCH o un emparejamiento concurrente.
        """
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

    async def retag_category(
        self, user_id: UUID, category_id: UUID, fiscal_tag: FiscalTag, now: datetime
    ) -> int:
        """Pone `fiscal_tag` a las transacciones de `category_id` del usuario, salvo las
        transferencias (invariante spec 004 SS2.5), y toca `updated_at` para el pull."""
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

    async def channels_for(self, ids: Sequence[UUID]) -> dict[UUID, list[Channel]]:
        """Canales unicos por transaccion, para armar el listado sin N+1 (spec 005 SS6).

        Una transaccion sin fuentes (o que no este en `ids`) no aparece como llave.
        """
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

    async def exists_name(
        self, user_id: UUID, name: str, *, exclude_id: UUID | None = None
    ) -> bool:
        """`True` si `name` choca, sin distinguir mayusculas, con una categoria visible para
        `user_id` (propia o del sistema) distinta de `exclude_id`."""
        ...

    async def add(self, category: Category) -> None: ...

    async def update(self, category: Category) -> None: ...

    async def delete(self, user_id: UUID, id: UUID) -> None: ...


# --- Cuentas vinculadas ----------------------------------------------------------------


class OwnerNamePort(Protocol):
    """Nombre del titular (el `display_name` de su cuenta), para reconocer
    transferencias propias (spec 004 SS4.1). `None` si no se conoce."""

    async def display_name(self, user_id: UUID) -> str | None: ...


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


# --- Cola de revision (spec 004 SS2.10, D1) ---------------------------------------


class ReviewQueueRepositoryPort(Protocol):
    """Persistencia de la cola de revision. Toda consulta filtra por `user_id`."""

    async def insert_if_absent(self, item: ReviewItem) -> bool:
        """Inserta `item`; `False` si `raw_message_id` ya existia (idempotente, P2)."""
        ...

    async def get(self, user_id: UUID, raw_message_id: UUID) -> ReviewItem | None:
        """Item propio por `raw_message_id`, o `None` si no existe o es ajeno."""
        ...

    async def list_open(self, user_id: UUID, cursor: Cursor | None, limit: int) -> list[ReviewItem]:
        """Items abiertos (`resolved_at IS NULL`) del usuario, keyset por
        `(created_at DESC, raw_message_id DESC)`.
        """
        ...

    async def resolve(
        self, user_id: UUID, raw_message_id: UUID, resolution: ReviewResolution, now: datetime
    ) -> bool:
        """Marca el item como resuelto; `False` si no existia, era ajeno o ya estaba
        resuelto (evita pisar una resolucion previa).
        """
        ...


class ReviewSourcePort(Protocol):
    """Cruce hacia el `raw_message` de un item de revision (D1: implementado por
    `infrastructure/raw_messages_gateway.py` delegando en `ingestion.public`).
    """

    async def load_views(self, user_id: UUID, ids: Sequence[UUID]) -> dict[UUID, ReviewSourceView]:
        """Vistas de los mensajes crudos propios cuyo id este en `ids`."""
        ...

    async def mark_status(self, raw_message_id: UUID, status: str, now: datetime) -> bool:
        """Actualiza el estado del `raw_message`; no comitea (el llamador controla
        la transaccion, mismo contrato que `ingestion.public.mark_raw_message`).
        """
        ...


# --- Infraestructura transversal ------------------------------------------------------


class EventPublisherPort(Protocol):
    """Publicacion de eventos de dominio (`luka.modules.ledger.events`)."""

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
    "OwnerNamePort",
    "ReviewQueueRepositoryPort",
    "ReviewSourcePort",
    "TransactionRepositoryPort",
    "TransactionSourceRepositoryPort",
    "UnitOfWorkPort",
]
