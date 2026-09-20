"""API publica de ledger: unico punto de entrada para otros modulos.

`record_captured_transaction` es la fachada que usara el modulo de parsing (Fase 2)
para registrar una captura sin conocer los adapters SQLAlchemy de ledger.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from finanzia.modules.ledger.application.dto import (
    CapturedTransactionCommand,
    Recorded,
    SourceInput,
)
from finanzia.modules.ledger.application.use_cases.record_captured_transaction import (
    RecordCapturedTransaction,
)
from finanzia.modules.ledger.events import TransactionCaptured
from finanzia.modules.ledger.infrastructure.event_publisher import BusEventPublisher
from finanzia.modules.ledger.infrastructure.id_generator import SecretsIdGenerator
from finanzia.modules.ledger.infrastructure.repositories import (
    SqlAlchemyCategoryRepository,
    SqlAlchemyLinkedAccountRepository,
    SqlAlchemyMerchantRuleRepository,
    SqlAlchemyTransactionRepository,
    SqlAlchemyTransactionSourceRepository,
)
from finanzia.modules.ledger.infrastructure.uow import SqlAlchemyUnitOfWork

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

    from finanzia.modules.ledger.application.ports import ClockPort
    from finanzia.shared.events.port import EventBusPort

__all__ = [
    "CapturedTransactionCommand",
    "Recorded",
    "SourceInput",
    "TransactionCaptured",
    "record_captured_transaction",
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
    """
    use_case = RecordCapturedTransaction(
        transactions=SqlAlchemyTransactionRepository(session),
        sources=SqlAlchemyTransactionSourceRepository(session),
        categories=SqlAlchemyCategoryRepository(session),
        accounts=SqlAlchemyLinkedAccountRepository(session),
        merchant_rules=SqlAlchemyMerchantRuleRepository(session),
        events=BusEventPublisher(event_bus),
        clock=clock,
        ids=SecretsIdGenerator(),
        uow=SqlAlchemyUnitOfWork(session),
    )
    return await use_case.execute(cmd)
