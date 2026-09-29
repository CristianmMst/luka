"""Adaptadores de identity sobre la fachada publica de ingestion.

Es el unico cruce de identity hacia ingestion (import-linter R4): solo
`finanzia.modules.ingestion.public`, nunca sus internals.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from finanzia.modules.ingestion import public as ingestion_public

if TYPE_CHECKING:
    from uuid import UUID

    from sqlalchemy.ext.asyncio import AsyncSession

    from finanzia.shared.settings import Settings


class IngestionGmailStatus:
    """Lee el estado de la conexion Gmail con la misma sesion del request."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def gmail_status(self, user_id: UUID) -> str:
        return await ingestion_public.gmail_connection_status(self._session, user_id)


class IngestionGmailCleanup:
    """`GmailCleanupPort`: desconecta Gmail antes de borrar la cuenta."""

    def __init__(
        self, session: AsyncSession, gmail: ingestion_public.GmailClientPort, settings: Settings
    ) -> None:
        self._session = session
        self._gmail = gmail
        self._settings = settings

    async def disconnect(self, user_id: UUID) -> None:
        await ingestion_public.disconnect_gmail(self._session, self._gmail, self._settings, user_id)


__all__ = ["IngestionGmailCleanup", "IngestionGmailStatus"]
