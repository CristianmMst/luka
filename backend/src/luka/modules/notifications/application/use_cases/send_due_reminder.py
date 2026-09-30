"""Consumer de `recurring.PaymentDueSoon`: envia el recordatorio push (spec 011 SS5)."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from decimal import Decimal
from uuid import UUID

from luka.modules.notifications.application.ports import (
    ClockPort,
    DeviceTokenRepositoryPort,
    PushSenderPort,
    RecurringRemindersPort,
    UnitOfWorkPort,
)
from luka.modules.notifications.domain.entities import SendOutcome
from luka.modules.notifications.domain.errors import PushUnavailable
from luka.modules.notifications.domain.messages import due_reminder_message


@dataclass(frozen=True, slots=True)
class DueReminderCommand:
    """Datos del evento `recurring.PaymentDueSoon`."""

    user_id: UUID
    occurrence_id: UUID
    name: str
    expected_amount: Decimal
    due_date: date
    today: date
    slot: int = 3


@dataclass(frozen=True, slots=True)
class ReminderResult:
    """Conteos del envio (lo unico que se loguea, P1)."""

    skipped: bool
    sent: int
    removed: int


class SendDueReminder:
    """Envia el aviso a todos los tokens del usuario y marca `reminded_at` si llego a uno.

    Si la ocurrencia ya se pago, se omitio o ya se aviso, no envia nada (AC-12.5). Los
    tokens que FCM declara invalidos se borran. Si FCM no respondio para ningun token
    (`PushUnavailable`) y ninguno recibio el aviso, se relanza para que el bus
    reintente; si al menos uno lo recibio, se marca y no se reintenta (reintentar
    duplicaria el aviso en los que si llego).
    """

    def __init__(
        self,
        *,
        tokens: DeviceTokenRepositoryPort,
        sender: PushSenderPort,
        reminders: RecurringRemindersPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._tokens = tokens
        self._sender = sender
        self._reminders = reminders
        self._clock = clock
        self._uow = uow

    async def execute(self, cmd: DueReminderCommand) -> ReminderResult:
        if not await self._reminders.still_due(cmd.occurrence_id, cmd.slot):
            return ReminderResult(skipped=True, sent=0, removed=0)
        message = due_reminder_message(
            occurrence_id=cmd.occurrence_id,
            name=cmd.name,
            amount=cmd.expected_amount,
            due_date=cmd.due_date,
            today=cmd.today,
        )
        sent = removed = 0
        unavailable: PushUnavailable | None = None
        for token in await self._tokens.list_for_user(cmd.user_id):
            try:
                outcome = await self._sender.send(token, message)
            except PushUnavailable as exc:
                unavailable = exc
                continue
            if outcome is SendOutcome.SENT:
                sent += 1
            else:
                await self._tokens.delete_token(token.token)
                removed += 1
        if sent:
            await self._reminders.mark_reminded(cmd.occurrence_id, cmd.slot)
        await self._uow.commit()
        if not sent and unavailable is not None:
            raise unavailable
        return ReminderResult(skipped=False, sent=sent, removed=removed)
