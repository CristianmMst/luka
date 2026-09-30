"""Unidad de trabajo SQLAlchemy: confirma los cambios de la sesion actual."""

from sqlalchemy.ext.asyncio import AsyncSession


class SqlAlchemyUnitOfWork:
    """Implementacion de `UnitOfWorkPort` sobre una `AsyncSession` existente."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()
