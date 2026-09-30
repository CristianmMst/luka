"""`UserDataExportPort` sobre las fachadas publicas de ledger e ingestion (R4).

Junta lo que el usuario tiene en otros modulos para `GET /v1/me/export`
(RF-11.2): los datos de ledger, sus gastos fijos (recurring) y el estado de su
conexion Gmail (sin token).
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from luka.modules.ingestion import public as ingestion_public

if TYPE_CHECKING:
    from uuid import UUID

    from sqlalchemy.ext.asyncio import AsyncSession


class ModulesDataExport:
    """Implementacion de `UserDataExportPort` con la sesion del request."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def export(self, user_id: UUID) -> dict[str, object]:
        # Import diferido: `ledger.public` importa `identity.public` (nombre del
        # titular, spec 004 SS4.1) y este modulo lo carga `identity.public` via
        # las dependencias de la API; importarlo arriba seria un ciclo.
        from luka.modules.ledger import public as ledger_public  # noqa: PLC0415
        from luka.modules.recurring import public as recurring_public  # noqa: PLC0415

        ledger = await ledger_public.export_user_data(self._session, user_id)
        recurring = await recurring_public.export_user_data(self._session, user_id)
        gmail = await ingestion_public.gmail_connection_status(self._session, user_id)
        return {**ledger, **recurring, "gmail": {"status": gmail}}


__all__ = ["ModulesDataExport"]
