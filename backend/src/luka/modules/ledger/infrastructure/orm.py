"""Modelos ORM de ledger: cuentas, categorias, transacciones, fuentes y reglas de
comerciante (spec 004 SS2.4-2.9, F1.5).
"""

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    REAL,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    Text,
    UniqueConstraint,
    desc,
    text,
)
from sqlalchemy.dialects.postgresql import ARRAY, JSONB
from sqlalchemy.orm import Mapped, mapped_column

from luka.shared.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

_BANK_VALUES = "'bancolombia','nequi','davivienda','daviplata','bbva','banco_bogota','other'"
_ACCOUNT_KIND_VALUES = "'savings','checking','credit_card','wallet'"
_DIRECTION_VALUES = "'debit','credit'"
_TRANSACTION_KIND_VALUES = "'expense','income','transfer'"
_CHANNEL_VALUES = "'email','notification','sms_notification','manual','nfc'"
_FISCAL_TAG_VALUES = (
    "'ingreso_laboral','ingreso_honorarios','ingreso_capital','ingreso_no_laboral',"
    "'ingreso_pension','deducible_salud','deducible_vivienda','aporte_pension_voluntaria',"
    "'aporte_afc','aporte_obligatorio','donacion','no_deducible','transferencia'"
)
_REASON_VALUES = (
    "'no_template','llm_disabled','llm_budget_exceeded','llm_invalid_json',"
    "'llm_invalid_output','llm_low_confidence','llm_error','body_purged'"
)
_RESOLUTION_VALUES = "'converted','discarded','reparsed'"


class CategoryRow(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Tabla `categories`: `user_id NULL` = categoria del sistema (spec 004 SS2.8)."""

    __tablename__ = "categories"
    __table_args__ = (
        CheckConstraint(f"fiscal_tag IN ({_FISCAL_TAG_VALUES})", name="fiscal_tag_valido"),
        CheckConstraint("(user_id IS NULL) = (slug IS NOT NULL)", name="slug_solo_sistema"),
        UniqueConstraint("user_id", "name", postgresql_nulls_not_distinct=True),
    )

    user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=True
    )
    slug: Mapped[str | None] = mapped_column(Text, unique=True, nullable=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    icon: Mapped[str | None] = mapped_column(Text, nullable=True)
    color: Mapped[str | None] = mapped_column(Text, nullable=True)
    fiscal_tag: Mapped[str] = mapped_column(Text, nullable=False)


class LinkedAccountRow(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Tabla `linked_accounts`: cuentas/tarjetas propias (spec 004 SS2.4)."""

    __tablename__ = "linked_accounts"
    __table_args__ = (
        CheckConstraint(f"bank IN ({_BANK_VALUES})", name="bank_valido"),
        CheckConstraint(f"kind IN ({_ACCOUNT_KIND_VALUES})", name="kind_valido"),
        CheckConstraint("last4 ~ '^[0-9]{1,4}$'", name="last4_digitos"),
        UniqueConstraint("user_id", "bank", "last4", postgresql_nulls_not_distinct=True),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    bank: Mapped[str] = mapped_column(Text, nullable=False)
    kind: Mapped[str] = mapped_column(Text, nullable=False)
    last4: Mapped[str | None] = mapped_column(Text, nullable=True)
    alias: Mapped[str | None] = mapped_column(Text, nullable=True)


class TransactionRow(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Tabla `transactions`: movimientos del usuario (spec 004 SS2.5)."""

    __tablename__ = "transactions"
    __table_args__ = (
        CheckConstraint("amount > 0", name="amount_positivo"),
        CheckConstraint(f"direction IN ({_DIRECTION_VALUES})", name="direction_valido"),
        CheckConstraint(f"kind IN ({_TRANSACTION_KIND_VALUES})", name="kind_valido"),
        CheckConstraint(f"bank IS NULL OR bank IN ({_BANK_VALUES})", name="bank_valido"),
        CheckConstraint(f"fiscal_tag IN ({_FISCAL_TAG_VALUES})", name="fiscal_tag_valido"),
        UniqueConstraint("user_id", "dedupe_key"),
        # Nombre explicito: la convencion de naming no resuelve columnas con
        # modificador DESC (expresiones, no `Column`), ver 0002_ledger_core.py.
        Index("ix_transactions_user_id_occurred_at_id", "user_id", desc("occurred_at"), desc("id")),
        Index(None, "user_id", "updated_at", "id"),
        Index(None, "user_id", "category_id"),
        Index(None, "user_id", "kind"),
        Index(None, "transfer_pair_id"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    currency: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'COP'"))
    direction: Mapped[str] = mapped_column(Text, nullable=False)
    kind: Mapped[str] = mapped_column(Text, nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    merchant: Mapped[str | None] = mapped_column(Text, nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    bank: Mapped[str | None] = mapped_column(Text, nullable=True)
    account_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("linked_accounts.id", ondelete="SET NULL"), nullable=True
    )
    category_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("categories.id", ondelete="RESTRICT"), nullable=False
    )
    fiscal_tag: Mapped[str] = mapped_column(Text, nullable=False)
    transfer_pair_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("transactions.id", ondelete="SET NULL"), nullable=True
    )
    transfer_auto: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false")
    )
    transfer_exclusions: Mapped[list[object]] = mapped_column(
        JSONB, nullable=False, server_default=text("'[]'")
    )
    dedupe_key: Mapped[str] = mapped_column(Text, nullable=False)
    parsed_by: Mapped[str] = mapped_column(Text, nullable=False)
    confidence: Mapped[float | None] = mapped_column(REAL, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class TransactionSourceRow(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Tabla `transaction_sources`: evidencias de una transaccion (spec 004 SS2.6)."""

    __tablename__ = "transaction_sources"
    __table_args__ = (
        CheckConstraint(f"channel IN ({_CHANNEL_VALUES})", name="channel_valido"),
        Index(
            "uq_transaction_sources_transaction_id_raw_message_id",
            "transaction_id",
            "raw_message_id",
            unique=True,
            postgresql_where=text("raw_message_id IS NOT NULL"),
        ),
        Index(None, "transaction_id"),
    )

    transaction_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("transactions.id", ondelete="CASCADE"), nullable=False
    )
    # `SET NULL` (no CASCADE): la evidencia sobrevive al borrado del mensaje crudo;
    # el job de purga (F3.7) solo anula `raw_messages.body` (spec 004 SS2.6).
    raw_message_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("raw_messages.id", ondelete="SET NULL"), nullable=True
    )
    channel: Mapped[str] = mapped_column(Text, nullable=False)
    received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class MerchantRuleRow(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Tabla `merchant_rules`: aprendizaje de correcciones (spec 004 SS2.9)."""

    __tablename__ = "merchant_rules"
    __table_args__ = (UniqueConstraint("user_id", "merchant_pattern"),)

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    merchant_pattern: Mapped[str] = mapped_column(Text, nullable=False)
    category_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("categories.id", ondelete="CASCADE"), nullable=False
    )


class ReviewQueueRow(Base, TimestampMixin):
    """Tabla `review_queue`: mensajes crudos que requieren revision manual (spec 004
    SS2.10, F2.1). Duena: ledger (ver ruling D1); `user_id` va denormalizado para
    filtrar por usuario sin join cross-modulo hacia `raw_messages` (ingestion).
    """

    __tablename__ = "review_queue"
    __table_args__ = (
        CheckConstraint(f"reason IN ({_REASON_VALUES})", name="reason_valido"),
        CheckConstraint(
            f"resolution IS NULL OR resolution IN ({_RESOLUTION_VALUES})",
            name="resolution_valida",
        ),
        CheckConstraint(
            "(resolved_at IS NULL) = (resolution IS NULL)", name="resolucion_consistente"
        ),
        # Cola de pendientes por usuario, mas recientes primero; `resolved_at IS NULL`
        # la mantiene pequena (indice parcial) frente al historial ya resuelto.
        Index(
            "ix_review_queue_user_id_created_at_raw_message_id",
            "user_id",
            desc("created_at"),
            desc("raw_message_id"),
            postgresql_where=text("resolved_at IS NULL"),
        ),
    )

    raw_message_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("raw_messages.id", ondelete="CASCADE"), primary_key=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    partial_extract: Mapped[dict[str, object]] = mapped_column(
        JSONB, nullable=False, server_default=text("'{}'")
    )
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    resolution: Mapped[str | None] = mapped_column(Text, nullable=True)


class TransactionTombstoneRow(Base, UUIDPrimaryKeyMixin):
    """Tabla `transaction_tombstones`: lapidas de capturas borradas (spec 004 SS2.16, SS3).

    Solo lo necesario para reconocer otra fuente de la misma compra (P6); se purgan
    a los 7 dias (cron diario de ledger).
    """

    __tablename__ = "transaction_tombstones"
    __table_args__ = (
        CheckConstraint("amount > 0", name="amount_positivo"),
        CheckConstraint(f"direction IN ({_DIRECTION_VALUES})", name="direction_valido"),
        CheckConstraint(f"bank IN ({_BANK_VALUES})", name="bank_valido"),
        Index(None, "user_id", "occurred_at"),
        Index(None, "deleted_at"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    dedupe_key: Mapped[str] = mapped_column(Text, nullable=False)
    bank: Mapped[str] = mapped_column(Text, nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    direction: Mapped[str] = mapped_column(Text, nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    channels: Mapped[list[str]] = mapped_column(ARRAY(Text), nullable=False)
    origin: Mapped[str] = mapped_column(Text, nullable=False)
    deleted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
