"""`RecurringRemindersPort` sobre `recurring.public` (R4)."""

from __future__ import annotations

from typing import TYPE_CHECKING

from luka.modules.recurring import public as recurring_public

if TYPE_CHECKING:
    from uuid import UUID

    from sqlalchemy.ext.asyncio import AsyncSession

    from luka.modules.notifications.application.ports import ClockPort


class RecurringReminders:
    """Consulta y marca el aviso de una ocurrencia en la misma sesion del consumer."""

    def __init__(self, session: AsyncSession, clock: ClockPort) -> None:
        self._session = session
        self._clock = clock

    async def still_due(self, occurrence_id: UUID, days_before: int) -> bool:
        return await recurring_public.reminder_still_due(
            self._session, self._clock, occurrence_id, days_before
        )

    async def mark_reminded(self, occurrence_id: UUID, days_before: int) -> bool:
        return await recurring_public.mark_reminded(
            self._session, self._clock, occurrence_id, days_before
        )


__all__ = ["RecurringReminders"]
