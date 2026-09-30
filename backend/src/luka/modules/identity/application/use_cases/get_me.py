"""Caso de uso: consultar el perfil del usuario autenticado."""

from uuid import UUID

from luka.modules.identity.application.dto import MeResult, build_connections
from luka.modules.identity.application.ports import (
    GmailConnectionStatusPort,
    UserRepositoryPort,
)
from luka.modules.identity.domain.errors import UserNotFound


class GetMe:
    """Obtiene el perfil de un usuario junto con el estado de sus conexiones."""

    def __init__(self, *, users: UserRepositoryPort, gmail: GmailConnectionStatusPort) -> None:
        self._users = users
        self._gmail = gmail

    async def execute(self, user_id: UUID) -> MeResult:
        """Devuelve el `MeResult` del usuario o lanza `UserNotFound`."""
        user = await self._users.get_by_id(user_id)
        if user is None:
            raise UserNotFound
        gmail_status = await self._gmail.gmail_status(user_id)
        return MeResult(user=user, connections=build_connections(user, gmail_status))
