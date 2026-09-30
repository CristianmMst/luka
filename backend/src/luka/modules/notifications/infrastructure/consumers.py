"""Handler de `recurring.PaymentDueSoon`: envia el recordatorio push (spec 011 SS5).

Se tipa contra `recurring.events` (entrada explicita en R4). Solo loguea conteos,
nunca el nombre ni el monto del gasto fijo ni los tokens (P1).
"""

from __future__ import annotations

from datetime import date
from typing import TYPE_CHECKING

import structlog

from luka.modules.notifications.application.use_cases.send_due_reminder import (
    DueReminderCommand,
    SendDueReminder,
)
from luka.modules.notifications.infrastructure.recurring_gateway import RecurringReminders
from luka.modules.notifications.infrastructure.repositories import SqlAlchemyDeviceTokenRepository
from luka.modules.notifications.infrastructure.uow import SqlAlchemyUnitOfWork
from luka.modules.recurring.events import PaymentDueSoon

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

    from luka.modules.notifications.application.ports import ClockPort, PushSenderPort
    from luka.shared.events.port import EventHandler

_logger = structlog.get_logger()


def _colombia_today(clock: ClockPort) -> date:
    from zoneinfo import ZoneInfo  # noqa: PLC0415

    return clock.now().astimezone(ZoneInfo("America/Bogota")).date()


def make_payment_due_soon_handler(
    *,
    session_factory: async_sessionmaker[AsyncSession],
    sender: PushSenderPort,
    clock: ClockPort,
) -> EventHandler:
    """`EventHandler` del grupo `notifications` de `recurring.PaymentDueSoon`."""

    async def handler(event: object) -> None:
        if not isinstance(event, PaymentDueSoon):
            _logger.warning("notifications_consumer_invalid_event", event_type=type(event).__name__)
            return
        cmd = DueReminderCommand(
            user_id=event.user_id,
            occurrence_id=event.occurrence_id,
            name=event.name,
            expected_amount=event.expected_amount,
            due_date=date.fromisoformat(event.due_date),
            today=_colombia_today(clock),
            days_before=event.days_before,
        )
        async with session_factory() as session:
            use_case = SendDueReminder(
                tokens=SqlAlchemyDeviceTokenRepository(session),
                sender=sender,
                reminders=RecurringReminders(session, clock),
                clock=clock,
                uow=SqlAlchemyUnitOfWork(session),
            )
            result = await use_case.execute(cmd)
        _logger.info(
            "push_sent",
            skipped=result.skipped,
            sent=result.sent,
            removed=result.removed,
        )

    return handler


__all__ = ["make_payment_due_soon_handler"]
