"""Caso de uso: consultar el perfil del usuario autenticado."""

from uuid import UUID

from finanzia.modules.identity.application.dto import MeResult, build_connections
from finanzia.modules.identity.application.ports import UserRepositoryPort
from finanzia.modules.identity.domain.errors import UserNotFound


class GetMe:
    """Obtiene el perfil de un usuario junto con el estado de sus conexiones."""

    def __init__(self, *, users: UserRepositoryPort) -> None:
        self._users = users

    async def execute(self, user_id: UUID) -> MeResult:
        """Devuelve el `MeResult` del usuario o lanza `UserNotFound`."""
        user = await self._users.get_by_id(user_id)
        if user is None:
            raise UserNotFound
        return MeResult(user=user, connections=build_connections(user))
