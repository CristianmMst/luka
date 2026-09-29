"""Adaptador de `OwnerNamePort` sobre `identity.public` (R4).

Como `raw_messages_gateway.py`: R2 prohibe que `application` importe el
`public.py` de otro modulo, asi que el cruce vive aqui, en `infrastructure`.
"""

from __future__ import annotations

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from finanzia.modules.identity.public import load_display_name


class IdentityOwnerNames:
    """Implementacion de `OwnerNamePort` delegando en `identity.public`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def display_name(self, user_id: UUID) -> str | None:
        return await load_display_name(self._session, user_id)


__all__ = ["IdentityOwnerNames"]
