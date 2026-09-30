"""Modelo ORM de notifications: `device_tokens` (spec 004 SS2.15)."""

import uuid
from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from luka.shared.db.base import Base, UUIDPrimaryKeyMixin

_PLATFORM_VALUES = "'android','ios'"


class DeviceTokenRow(Base, UUIDPrimaryKeyMixin):
    """Tabla `device_tokens`: un token de FCM pertenece a un solo usuario."""

    __tablename__ = "device_tokens"
    __table_args__ = (
        CheckConstraint(f"platform IN ({_PLATFORM_VALUES})", name="platform_valido"),
        Index(None, "user_id"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    token: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    platform: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
