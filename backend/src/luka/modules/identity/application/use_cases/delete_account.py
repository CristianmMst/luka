"""Caso de uso: borrar la cuenta (RF-11.3, AC-11.3, spec 004 SS6).

Borrado inmediato: primero Gmail (para el watch y revoca el grant en Google,
best effort), luego el usuario, y el `ON DELETE CASCADE` se lleva movimientos,
correos guardados, cuentas, categorias propias, reglas, revision y refresh
tokens. El access JWT vigente (≤ 15 min) sigue firmado, pero ya no hay usuario
detras. La verificacion de ≤ 72 h y la web de borrado quedan para F6.4/F6.5.
"""

from __future__ import annotations

from uuid import UUID

from luka.modules.identity.application.ports import (
    AuditLogPort,
    ClockPort,
    EventPublisherPort,
    GmailCleanupPort,
    RefreshTokenRepositoryPort,
    TokenGeneratorPort,
    UnitOfWorkPort,
    UserRepositoryPort,
)
from luka.modules.identity.domain.errors import UserNotFound
from luka.modules.identity.events import UserDeleted


class DeleteAccount:
    """Borra al usuario y todos sus datos; publica `UserDeleted`."""

    def __init__(  # noqa: PLR0913 - un puerto por dependencia externa
        self,
        *,
        users: UserRepositoryPort,
        tokens: RefreshTokenRepositoryPort,
        gmail: GmailCleanupPort,
        events: EventPublisherPort,
        audit: AuditLogPort,
        clock: ClockPort,
        ids: TokenGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._users = users
        self._tokens = tokens
        self._gmail = gmail
        self._events = events
        self._audit = audit
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(self, user_id: UUID) -> None:
        """Lanza `UserNotFound` si el usuario ya no existe."""
        if await self._users.get_by_id(user_id) is None:
            raise UserNotFound
        # Gmail va antes: sin la fila de conexion ya no habria token que revocar.
        await self._gmail.disconnect(user_id)
        now = self._clock.now()
        # El CASCADE tambien los borra; revocarlos primero cierra la ventana si
        # el borrado fallara a mitad (spec 009: borrar la cuenta revoca todo).
        await self._tokens.revoke_all_for_user(user_id, now)
        await self._users.delete(user_id)
        await self._uow.commit()
        self._audit.record("account_deleted", user_id=user_id)
        await self._events.publish(
            UserDeleted(event_id=self._ids.new_id(), occurred_at=now, user_id=user_id)
        )


__all__ = ["DeleteAccount"]
