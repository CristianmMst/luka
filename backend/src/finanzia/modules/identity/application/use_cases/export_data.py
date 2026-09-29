"""Caso de uso: exportar los datos del usuario (RF-11.2, AC-11.2).

Sincrono y en JSON: el perfil de identity mas lo que exportan los otros
modulos (movimientos, cuentas, categorias propias, reglas, revision, estado de
Gmail). El Excel y el job asincrono de spec 005 SS2 quedan para F6.4.
"""

from __future__ import annotations

from uuid import UUID

from finanzia.modules.identity.application.ports import (
    AuditLogPort,
    ClockPort,
    UserDataExportPort,
    UserRepositoryPort,
)
from finanzia.modules.identity.domain.errors import UserNotFound

EXPORT_FORMAT_VERSION = 1


class ExportUserData:
    """Arma el documento de exportacion del usuario."""

    def __init__(
        self,
        *,
        users: UserRepositoryPort,
        data: UserDataExportPort,
        audit: AuditLogPort,
        clock: ClockPort,
    ) -> None:
        self._users = users
        self._data = data
        self._audit = audit
        self._clock = clock

    async def execute(self, user_id: UUID) -> dict[str, object]:
        """Lanza `UserNotFound` si el usuario no existe."""
        user = await self._users.get_by_id(user_id)
        if user is None:
            raise UserNotFound
        document: dict[str, object] = {
            "format_version": EXPORT_FORMAT_VERSION,
            "exported_at": self._clock.now().isoformat(),
            "profile": {
                "email": user.email,
                "display_name": user.display_name,
                "created_at": user.created_at.isoformat(),
            },
            **await self._data.export(user_id),
        }
        self._audit.record("data_exported", user_id=user_id)
        return document


__all__ = ["EXPORT_FORMAT_VERSION", "ExportUserData"]
