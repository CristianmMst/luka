"""Caso de uso: purga de cuerpos vencidos (spec 004 §6, F3.7)."""

from datetime import datetime

from finanzia.modules.ingestion.application.ports import RawMessageRepositoryPort, UnitOfWorkPort


class PurgeExpiredBodies:
    """Pone `body=NULL` en las filas con `purge_after < now` (retencion de 90 dias)."""

    def __init__(self, *, repo: RawMessageRepositoryPort, uow: UnitOfWorkPort) -> None:
        self._repo = repo
        self._uow = uow

    async def execute(self, now: datetime) -> int:
        count = await self._repo.purge_bodies(now, now)
        await self._uow.commit()
        return count


__all__ = ["PurgeExpiredBodies"]
