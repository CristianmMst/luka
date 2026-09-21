"""Modelos ORM de ingestion: mensajes crudos capturados por email/notificacion
(spec 004 SS2.7, F2.1).
"""

import uuid
from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Text, UniqueConstraint, text
from sqlalchemy.orm import Mapped, mapped_column

from finanzia.shared.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

_CHANNEL_VALUES = "'email','notification','sms_notification'"
_BANK_VALUES = "'bancolombia','nequi','davivienda','daviplata','bbva','banco_bogota','other'"
_STATUS_VALUES = "'pending','parsed','failed','discarded','reviewed'"


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
