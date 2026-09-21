"""Caso de uso: convertir un item de revision en una transaccion manual (D1, AC-9.3).

Compone `CreateManualTransaction.create` (sin comitear, ver su docstring) para
insertar la transaccion con la evidencia real del `raw_message` como fuente, y
comitea una unica vez junto con la resolucion de la cola de revision y el marcado
del mensaje crudo como `reviewed` (una sola unidad de trabajo, spec 003 SS2.3).
"""

from finanzia.modules.ledger.application.dto import (
    ConvertReviewCommand,
    ManualTransactionCommand,
    SourceInput,
    TransactionDetail,
)
from finanzia.modules.ledger.application.ports import (
    ClockPort,
    EventPublisherPort,
    IdGeneratorPort,
    ReviewQueueRepositoryPort,
    ReviewSourcePort,
    UnitOfWorkPort,
)
from finanzia.modules.ledger.application.use_cases.create_manual_transaction import (
    CreateManualTransaction,
)
from finanzia.modules.ledger.application.use_cases.get_transaction import GetTransaction
from finanzia.modules.ledger.domain.errors import ReviewAlreadyResolved, ReviewItemNotFound
from finanzia.modules.ledger.domain.review import ReviewResolution
from finanzia.modules.ledger.events import TransactionCaptured


class ConvertReviewItem:
    """Cierra un item de revision creando la transaccion manual correspondiente."""

    def __init__(  # noqa: PLR0913 - un puerto/colaborador por dependencia externa
        self,
        *,
        review_queue: ReviewQueueRepositoryPort,
        review_source: ReviewSourcePort,
        create_manual: CreateManualTransaction,
        get_transaction: GetTransaction,
        events: EventPublisherPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._review_queue = review_queue
        self._review_source = review_source
        self._create_manual = create_manual
        self._get_transaction = get_transaction
        self._events = events
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(self, cmd: ConvertReviewCommand) -> TransactionDetail:
        """`ReviewItemNotFound` (ajeno/inexistente) o `ReviewAlreadyResolved` (409)."""
        item = await self._review_queue.get(cmd.user_id, cmd.raw_message_id)
        if item is None:
            raise ReviewItemNotFound
        if not item.is_open:
            raise ReviewAlreadyResolved

        views = await self._review_source.load_views(cmd.user_id, [cmd.raw_message_id])
        view = views.get(cmd.raw_message_id)
        if view is None:
            # El `raw_message` referenciado por la fila de revision desaparecio
            # (inconsistencia inesperada: el FK es CASCADE, no deberia ocurrir).
            raise ReviewItemNotFound

        manual_cmd = ManualTransactionCommand(
            user_id=cmd.user_id,
            amount=cmd.amount,
            direction=cmd.direction,
            occurred_at=cmd.occurred_at,
            category_id=cmd.category_id,
            merchant=cmd.merchant,
            description=cmd.description,
            account_id=cmd.account_id,
            notes=cmd.notes,
            channel=view.channel,
            kind=cmd.kind,
        )
        source_override = SourceInput(
            channel=view.channel, raw_message_id=cmd.raw_message_id, received_at=view.received_at
        )
        tx = await self._create_manual.create(manual_cmd, source_override=source_override)

        now = self._clock.now()
        await self._review_queue.resolve(
            cmd.user_id, cmd.raw_message_id, ReviewResolution.CONVERTED, now
        )
        await self._review_source.mark_status(cmd.raw_message_id, "reviewed", now)

        await self._uow.commit()
        await self._events.publish(
            TransactionCaptured(
                event_id=self._ids.new_id(),
                occurred_at=tx.created_at,
                user_id=cmd.user_id,
                transaction_id=tx.id,
                kind=tx.kind,
                fiscal_tag=tx.fiscal_tag,
                amount=tx.amount,
                direction=tx.direction,
                category_id=tx.category_id,
                transaction_occurred_at=tx.occurred_at,
                created=True,
            )
        )

        return await self._get_transaction.execute(cmd.user_id, tx.id)
