"""Adaptador de `GmailConnectionStatusPort` sobre la fachada publica de ingestion.

Es el unico cruce de identity hacia ingestion (import-linter R4): solo
`finanzia.modules.ingestion.public`, nunca sus internals.
"""

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from finanzia.modules.ingestion import public as ingestion_public


class IngestionGmailStatus:
    """Lee el estado de la conexion Gmail con la misma sesion del request."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def gmail_status(self, user_id: UUID) -> str:
        return await ingestion_public.gmail_connection_status(self._session, user_id)


__all__ = ["IngestionGmailStatus"]
