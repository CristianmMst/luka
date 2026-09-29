"""API publica de identity: unico punto de entrada para otros modulos."""

from __future__ import annotations

from typing import TYPE_CHECKING

from finanzia.modules.identity.events import UserDeleted
from finanzia.modules.identity.infrastructure.api.deps import get_current_user_id
from finanzia.modules.identity.infrastructure.repositories import SqlAlchemyUserRepository

if TYPE_CHECKING:
    from uuid import UUID

    from sqlalchemy.ext.asyncio import AsyncSession


async def load_display_name(session: AsyncSession, user_id: UUID) -> str | None:
    """Nombre del usuario tal como lo da Google (`None` si no existe o no lo
    tiene). Ledger lo usa para reconocer transferencias propias (spec 004 §4.1).
    """
    user = await SqlAlchemyUserRepository(session).get_by_id(user_id)
    return user.display_name if user is not None else None


__all__ = ["UserDeleted", "get_current_user_id", "load_display_name"]
