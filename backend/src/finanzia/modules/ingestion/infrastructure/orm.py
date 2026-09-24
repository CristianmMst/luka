"""Modelos ORM de ingestion: mensajes crudos capturados por email/notificacion
(spec 004 SS2.7, F2.1).
"""

import uuid
from datetime import datetime

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    LargeBinary,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from finanzia.shared.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

_CHANNEL_VALUES = "'email','notification','sms_notification'"
_BANK_VALUES = "'bancolombia','nequi','davivienda','daviplata','bbva','banco_bogota','other'"
_STATUS_VALUES = "'pending','parsed','failed','discarded','reviewed'"
_GMAIL_CONNECTION_STATUS_VALUES = "'active','revoked','error'"


class RawMessageRow(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Tabla `raw_messages`: mensajes crudos ingeridos, previos al parseo (spec 004 SS2.7)."""

    __tablename__ = "raw_messages"
    __table_args__ = (
        CheckConstraint(f"channel IN ({_CHANNEL_VALUES})", name="channel_valido"),
        CheckConstraint(f"bank IS NULL OR bank IN ({_BANK_VALUES})", name="bank_valido"),
        CheckConstraint(f"status IN ({_STATUS_VALUES})", name="status_valido"),
        UniqueConstraint("user_id", "channel", "external_id"),
        Index(None, "user_id", "status"),
        # Solo interesa purgar filas con `body` aun presente (F3.7); el job de
        # purga recorre esta particion parcial en vez de la tabla completa.
        Index(
            "ix_raw_messages_purge_after",
            "purge_after",
            postgresql_where=text("body IS NOT NULL"),
        ),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    channel: Mapped[str] = mapped_column(Text, nullable=False)
    external_id: Mapped[str] = mapped_column(Text, nullable=False)
    sender: Mapped[str] = mapped_column(Text, nullable=False)
    bank: Mapped[str | None] = mapped_column(Text, nullable=True)
    body: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'pending'"))
    received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    purge_after: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    # Veces que el cron de reencolado republico `RawMessageReceived` para esta fila
    # (riesgo 4 / D9): acota el ciclo cron -> DLQ -> sigue `pending` -> cron ...
    requeue_attempts: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))


class GmailConnectionRow(Base, TimestampMixin):
    """Tabla `gmail_connections`: conexion Gmail 1:1 con `users` (spec 004 §2.3, F3.2)."""

    __tablename__ = "gmail_connections"
    __table_args__ = (
        CheckConstraint(f"status IN ({_GMAIL_CONNECTION_STATUS_VALUES})", name="status_valido"),
        # El webhook push resuelve el usuario por la cuenta Gmail (spec 005 §4).
        Index(None, "email"),
    )

    # PK y FK a la vez (relacion 1:1): no usa `UUIDPrimaryKeyMixin`, que genera un
    # `id` propio.
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    email: Mapped[str] = mapped_column(Text, nullable=False)
    # Blob AES-256-GCM (`shared/crypto/aesgcm.py`): nonce (12 B) + ciphertext con
    # tag. El refresh token en claro nunca llega a esta fila (spec 009 §1/§3).
    refresh_token_enc: Mapped[bytes] = mapped_column(LargeBinary, nullable=False)
    history_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    watch_expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'active'"))
    last_sync_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
