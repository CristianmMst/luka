"""Caso de uso: listar las categorias visibles del usuario (spec 005 SS7)."""

from uuid import UUID

from luka.modules.ledger.application.ports import CategoryRepositoryPort
from luka.modules.ledger.domain.entities import Category


class ListCategories:
    """Devuelve las categorias del sistema y las propias del usuario."""

    def __init__(self, *, categories: CategoryRepositoryPort) -> None:
        self._categories = categories

    async def execute(self, user_id: UUID) -> list[Category]:
        return await self._categories.list_visible(user_id)
