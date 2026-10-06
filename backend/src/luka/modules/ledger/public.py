"""API publica de ledger: unico punto de entrada para otros modulos.

`record_captured_transaction` es la fachada que usara el modulo de parsing (Fase 2)
para registrar una captura sin conocer los adapters SQLAlchemy de ledger.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from luka.modules.ledger.application.dto import (
    CapturedTransactionCommand,
    Recorded,
    SourceInput,
)
from luka.modules.ledger.application.use_cases.mark_self_transfers import (
    MarkSelfTransfers,
    MarkSelfTransfersSummary,
)
from luka.modules.ledger.application.use_cases.record_captured_transaction import (
    RecordCapturedTransaction,
)
from luka.modules.ledger.application.use_cases.split_merged_captures import (
    SplitMergedCaptures,
    SplitMergedCapturesSummary,
)
from luka.modules.ledger.events import TransactionCaptured, TransactionDeleted
from luka.modules.ledger.infrastructure import snapshots as _snapshots
from luka.modules.ledger.infrastructure.data_export import export_ledger_data
from luka.modules.ledger.infrastructure.event_publisher import BusEventPublisher
from luka.modules.ledger.infrastructure.id_generator import SecretsIdGenerator
from luka.modules.ledger.infrastructure.owner_name_gateway import IdentityOwnerNames
from luka.modules.ledger.infrastructure.repositories import (
    SqlAlchemyCategoryRepository,
    SqlAlchemyLinkedAccountRepository,
    SqlAlchemyMerchantRuleRepository,
    SqlAlchemyReviewQueueRepository,
    SqlAlchemyTransactionRepository,
    SqlAlchemyTransactionSourceRepository,
)
from luka.modules.ledger.infrastructure.snapshots import TransactionSnapshot
from luka.modules.ledger.infrastructure.uow import SqlAlchemyUnitOfWork

if TYPE_CHECKING:
    from collections.abc import Collection, Sequence
    from datetime import datetime
    from uuid import UUID

    from sqlalchemy.ext.asyncio import AsyncSession

    from luka.modules.ledger.application.ports import CaptureReaderPort, ClockPort
    from luka.shared.events.port import EventBusPort

__all__ = [
    "CapturedTransactionCommand",
    "MarkSelfTransfersSummary",
    "Recorded",
    "SourceInput",
    "SplitMergedCapturesSummary",
    "TransactionCaptured",
    "TransactionDeleted",
    "TransactionSnapshot",
    "account_owned",
    "category_visible",
    "expenses_in_window",
    "export_user_data",
    "get_transaction_snapshot",
    "mark_self_transfers",
    "record_captured_transaction",
    "split_merged_captures",
    "transaction_snapshots",
]


async def record_captured_transaction(
    session: AsyncSession,
    event_bus: EventBusPort,
    clock: ClockPort,
    cmd: CapturedTransactionCommand,
) -> Recorded:
    """Registra una captura entrante (email/notificacion/SMS/NFC) sobre `session`.

    Ensambla `RecordCapturedTransaction` con los repositorios SQLAlchemy y publica
    en `event_bus` (spec 004 SS3, AC-5.1/5.2). El llamador es responsable de la
    `session` (scope, cierre) igual que cualquier otro caso de uso de ledger.
    Lanza `CaptureAlreadyResolved` si el usuario ya convirtio o descarto el item de
    revision de ese `raw_message` (spec 006 SS4.4); no se escribe nada.
    """
    return await _record_use_case(session, event_bus, clock).execute(cmd)


def _record_use_case(
    session: AsyncSession, event_bus: EventBusPort, clock: ClockPort
) -> RecordCapturedTransaction:
    return RecordCapturedTransaction(
        transactions=SqlAlchemyTransactionRepository(session),
        sources=SqlAlchemyTransactionSourceRepository(session),
        categories=SqlAlchemyCategoryRepository(session),
        accounts=SqlAlchemyLinkedAccountRepository(session),
        merchant_rules=SqlAlchemyMerchantRuleRepository(session),
        review_queue=SqlAlchemyReviewQueueRepository(session),
        owner_names=IdentityOwnerNames(session),
        events=BusEventPublisher(event_bus),
        clock=clock,
        ids=SecretsIdGenerator(),
        uow=SqlAlchemyUnitOfWork(session),
    )


async def split_merged_captures(  # noqa: PLR0913 - un parametro por dependencia externa + filtros
    session: AsyncSession,
    event_bus: EventBusPort,
    clock: ClockPort,
    *,
    reader: CaptureReaderPort,
    person_parsed_by: Collection[str],
    user_id: UUID | None,
) -> SplitMergedCapturesSummary:
    """Separa las capturas entre personas que el dedupe viejo fusiono (spec 004
    SS3); `reader` re-parsea cada fuente y `person_parsed_by` lo da parsing."""
    use_case = SplitMergedCaptures(
        transactions=SqlAlchemyTransactionRepository(session),
        sources=SqlAlchemyTransactionSourceRepository(session),
        reader=reader,
        record=_record_use_case(session, event_bus, clock),
        clock=clock,
        uow=SqlAlchemyUnitOfWork(session),
    )
    return await use_case.execute(person_parsed_by=person_parsed_by, user_id=user_id)


async def export_user_data(session: AsyncSession, user_id: UUID) -> dict[str, object]:
    """Datos de ledger de `user_id` para `GET /v1/me/export` (RF-11.2)."""
    return await export_ledger_data(session, user_id)


async def mark_self_transfers(
    session: AsyncSession,
    clock: ClockPort,
    *,
    person_parsed_by: Collection[str],
    user_id: UUID | None,
) -> MarkSelfTransfersSummary:
    """Reclasifica como transferencia las capturas entre personas hechas al
    propio titular (spec 004 SS4.1); `person_parsed_by` lo da parsing."""
    use_case = MarkSelfTransfers(
        transactions=SqlAlchemyTransactionRepository(session),
        owner_names=IdentityOwnerNames(session),
        clock=clock,
        uow=SqlAlchemyUnitOfWork(session),
    )
    return await use_case.execute(person_parsed_by=person_parsed_by, user_id=user_id)


# --- Lecturas para recurring (spec 011 SS4) -----------------------------------------


async def get_transaction_snapshot(
    session: AsyncSession, user_id: UUID, id: UUID
) -> TransactionSnapshot | None:
    """Transaccion propia de `user_id`, o `None` si no existe o es ajena."""
    return await _snapshots.get_snapshot(session, user_id, id)


async def transaction_snapshots(
    session: AsyncSession, user_id: UUID, ids: Sequence[UUID]
) -> list[TransactionSnapshot]:
    """Transacciones propias con esos ids (las ajenas o borradas se omiten)."""
    return await _snapshots.snapshots(session, user_id, ids)


async def expenses_in_window(
    session: AsyncSession, user_id: UUID, start: datetime, end: datetime
) -> list[TransactionSnapshot]:
    """Gastos propios (`expense` + `debit`) con `start <= occurred_at < end`."""
    return await _snapshots.expenses_in_window(session, user_id, start, end)


async def category_visible(session: AsyncSession, user_id: UUID, id: UUID) -> bool:
    """`True` si la categoria es del sistema o del usuario."""
    return await _snapshots.category_visible(session, user_id, id)


async def account_owned(session: AsyncSession, user_id: UUID, id: UUID) -> bool:
    """`True` si la cuenta vinculada es del usuario."""
    return await _snapshots.account_owned(session, user_id, id)
