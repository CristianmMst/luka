"""Modelos ORM de identity: `users` y `refresh_tokens` (spec 004 SS2.1-2.2, F1.1)."""

import uuid
from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Text, text
from sqlalchemy.dialects.postgresql import CITEXT, JSONB
from sqlalchemy.orm import Mapped, mapped_column

from finanzia.shared.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class UserRow(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Tabla `users`: identidad estable de Google y consentimientos (spec 004 SS2.1)."""

    __tablename__ = "users"
    __table_args__ = (
        CheckConstraint("status IN ('active','deletion_pending')", name="status_valido"),
    )

    google_sub: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    email: Mapped[str] = mapped_column(CITEXT, unique=True, nullable=False)
    display_name: Mapped[str | None] = mapped_column(Text, nullable=True)
    photo_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'active'"))
    consents: Mapped[dict[str, object]] = mapped_column(
        JSONB, nullable=False, server_default=text("'{}'")
    )


class RefreshTokenRow(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Tabla `refresh_tokens`: rotacion y deteccion de reuso (spec 004 SS2.2)."""

    __tablename__ = "refresh_tokens"
    __table_args__ = (
        Index(None, "user_id"),
        Index(None, "family_id"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    token_hash: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    family_id: Mapped[uuid.UUID] = mapped_column(nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    device_info: Mapped[str | None] = mapped_column(Text, nullable=True)
