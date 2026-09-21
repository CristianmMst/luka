"""Caso de uso: ingesta idempotente y agnostica de canal de un mensaje crudo.

Spec 006 §2.2-2.3 (filtro de remitentes, cuerpo), §3.2 (notificaciones/SMS), §4.4
(idempotencia de ingesta); AC-2.4 (descartar sin persistir); D9 (republicar
`RawMessageReceived` si el duplicado sigue `pending`).
"""

from datetime import datetime
from uuid import UUID

from finanzia.modules.ingestion.application.dto import (
    Accepted,
    Discarded,
    Duplicate,
    IngestOutcome,
    RawMessageInput,
)
from finanzia.modules.ingestion.application.ports import (
    ClockPort,
    EventPublisherPort,
    IdGeneratorPort,
    RawMessageRepositoryPort,
    SenderPolicyPort,
    UnitOfWorkPort,
)
from finanzia.modules.ingestion.domain.body import (
    compose_body,
    purge_after_for,
    truncate_utf8,
    validate_external_id,
)
from finanzia.modules.ingestion.domain.entities import RawMessage
from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus
from finanzia.modules.ingestion.domain.errors import IngestionError
from finanzia.modules.ingestion.events import RawMessageReceived

_RETENTION_DAYS_DEFAULT = 90
_BODY_MAX_BYTES_DEFAULT = 8192


class IngestRawMessage:
    """Filtra por remitente/paquete (D6), compone+trunca el cuerpo y aplica
    idempotencia de ingesta sobre `(user_id, channel, external_id)` (spec 006 §4.4).
    """

    def __init__(  # noqa: PLR0913 - un puerto/config por dependencia externa
        self,
        *,
        repo: RawMessageRepositoryPort,
        policy: SenderPolicyPort,
        events: EventPublisherPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
        retention_days: int = _RETENTION_DAYS_DEFAULT,
        body_max_bytes: int = _BODY_MAX_BYTES_DEFAULT,
    ) -> None:
        self._repo = repo
        self._policy = policy
        self._events = events
        self._clock = clock
        self._ids = ids
        self._uow = uow
        self._retention_days = retention_days
        self._body_max_bytes = body_max_bytes

    async def execute(self, input: RawMessageInput) -> IngestOutcome:
        # El formato de `external_id` se valida antes del filtro de aceptacion a
        # proposito: un `external_id` malformado es un bug del cliente y debe
        # surgir como 400 (InvalidExternalId) sin importar si el remitente/paquete
        # esta soportado o no; en ambos casos, de todas formas, nada se persiste.
        validate_external_id(input.channel, input.external_id)

        bank: str | None
        if input.channel is Channel.EMAIL:
            bank = self._policy.bank_for_email_sender(input.sender)
            if bank is None:
                # AC-2.4: se descarta sin tocar el repo ni el publisher, y sin
                # loguear sender/title/text (P1/P6) — eso lo hace `application`
                # devolviendo el `Discarded`; `infrastructure` decide si loguea.
                return Discarded("unsupported_sender")
        else:
            decision = self._policy.bank_for_notification(
                input.sender, input.channel.value, input.title
            )
            if not decision.accepted:
                return Discarded("unsupported_package")
            bank = decision.bank

        body = truncate_utf8(compose_body(input.title, input.text), self._body_max_bytes)
        msg = RawMessage(
            id=self._ids.new_id(),
            user_id=input.user_id,
            channel=input.channel,
            external_id=input.external_id,
            sender=input.sender,
            bank=bank,
            body=body,
            status=RawMessageStatus.PENDING,
            received_at=input.received_at,
            purge_after=purge_after_for(input.received_at, self._retention_days),
        )

        inserted_id = await self._repo.insert_if_absent(msg)
        if inserted_id is None:
            return await self._handle_duplicate(input)

        await self._uow.commit()
        await self._publish_received(msg.id, msg.user_id, msg.channel, msg.bank, msg.received_at)
        return Accepted(msg.id, bank=msg.bank)

    async def _handle_duplicate(self, input: RawMessageInput) -> IngestOutcome:
        existing = await self._repo.get_by_external_id(
            input.user_id, input.channel, input.external_id
        )
        if existing is None:
            # Carrera improbable: la fila desaparecio entre el INSERT y el SELECT
            # (p. ej. borrado concurrente). No hay nada razonable que reintentar aqui.
            raise IngestionError("raw_message duplicado sin fila resultante")

        if existing.status is RawMessageStatus.PENDING:
            # D9: mitiga la falta de outbox — si el publish original fallo tras el
            # commit, este reintento de ingesta vuelve a publicar el evento.
            await self._publish_received(
                existing.id, existing.user_id, existing.channel, existing.bank, existing.received_at
            )
            return Duplicate(existing.id, republished=True, bank=existing.bank)
        return Duplicate(existing.id, republished=False, bank=existing.bank)

    async def _publish_received(
        self,
        raw_message_id: UUID,
        user_id: UUID,
        channel: Channel,
        bank: str | None,
        received_at: datetime,
    ) -> None:
        await self._events.publish(
            RawMessageReceived(
                event_id=self._ids.new_id(),
                occurred_at=self._clock.now(),
                raw_message_id=raw_message_id,
                user_id=user_id,
                channel=channel.value,
                bank=bank,
                received_at=received_at,
            )
        )


__all__ = ["IngestRawMessage"]
