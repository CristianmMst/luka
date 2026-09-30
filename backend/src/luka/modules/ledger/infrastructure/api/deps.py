"""Wiring de dependencias FastAPI de ledger: unico lugar que ensambla adapters.

Los routers quedan deliberadamente "delgados": solo llaman a los casos de uso
obtenidos aqui (controller ruling 5). `get_session` es una copia local (no una
importacion) de la de identity: cada modulo es independiente salvo `public.py`/
`events.py` (import-linter R4).
"""

from collections.abc import AsyncIterator

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.identity.public import get_current_user_id
from luka.modules.ledger.application.use_cases.convert_review_item import ConvertReviewItem
from luka.modules.ledger.application.use_cases.create_account import CreateAccount
from luka.modules.ledger.application.use_cases.create_category import CreateCategory
from luka.modules.ledger.application.use_cases.create_manual_transaction import (
    CreateManualTransaction,
)
from luka.modules.ledger.application.use_cases.delete_account import DeleteAccount
from luka.modules.ledger.application.use_cases.delete_category import DeleteCategory
from luka.modules.ledger.application.use_cases.delete_transaction import DeleteTransaction
from luka.modules.ledger.application.use_cases.discard_review_item import DiscardReviewItem
from luka.modules.ledger.application.use_cases.get_transaction import GetTransaction
from luka.modules.ledger.application.use_cases.list_accounts import ListAccounts
from luka.modules.ledger.application.use_cases.list_categories import ListCategories
from luka.modules.ledger.application.use_cases.list_review import ListReview
from luka.modules.ledger.application.use_cases.list_transactions import ListTransactions
from luka.modules.ledger.application.use_cases.set_transfer_pair import SetTransferPair
from luka.modules.ledger.application.use_cases.unset_transfer_pair import UnsetTransferPair
from luka.modules.ledger.application.use_cases.update_account import UpdateAccount
from luka.modules.ledger.application.use_cases.update_category import UpdateCategory
from luka.modules.ledger.application.use_cases.update_transaction import UpdateTransaction
from luka.modules.ledger.infrastructure.event_publisher import BusEventPublisher
from luka.modules.ledger.infrastructure.id_generator import SecretsIdGenerator
from luka.modules.ledger.infrastructure.raw_messages_gateway import IngestionReviewSource
from luka.modules.ledger.infrastructure.repositories import (
    SqlAlchemyCategoryRepository,
    SqlAlchemyLinkedAccountRepository,
    SqlAlchemyMerchantRuleRepository,
    SqlAlchemyReviewQueueRepository,
    SqlAlchemyTransactionRepository,
    SqlAlchemyTransactionSourceRepository,
)
from luka.modules.ledger.infrastructure.uow import SqlAlchemyUnitOfWork
from luka.shared.clock import SystemClock

__all__ = ["get_current_user_id"]


async def get_session(request: Request) -> AsyncIterator[AsyncSession]:
    """Sesion por request desde `app.state.session_factory`; rollback si queda abierta."""
    async with request.app.state.session_factory() as session:
        try:
            yield session
        finally:
            if session.in_transaction():
                await session.rollback()


def get_clock() -> SystemClock:
    """Reloj real del sistema (UTC, aware)."""
    return SystemClock()


def get_ids() -> SecretsIdGenerator:
    """Generador de ids/aleatoriedad basado en `secrets`/`uuid`."""
    return SecretsIdGenerator()


def get_event_publisher(request: Request) -> BusEventPublisher:
    """Publicador de eventos sobre el bus compartido cableado en `app.state`."""
    return BusEventPublisher(request.app.state.event_bus)


def get_create_manual_transaction_use_case(
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
    ids: SecretsIdGenerator = Depends(get_ids),
    events: BusEventPublisher = Depends(get_event_publisher),
) -> CreateManualTransaction:
    return CreateManualTransaction(
        transactions=SqlAlchemyTransactionRepository(session),
        sources=SqlAlchemyTransactionSourceRepository(session),
        categories=SqlAlchemyCategoryRepository(session),
        accounts=SqlAlchemyLinkedAccountRepository(session),
        events=events,
        clock=clock,
        ids=ids,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_get_transaction_use_case(
    session: AsyncSession = Depends(get_session),
) -> GetTransaction:
    return GetTransaction(
        transactions=SqlAlchemyTransactionRepository(session),
        sources=SqlAlchemyTransactionSourceRepository(session),
    )


def get_list_transactions_use_case(
    session: AsyncSession = Depends(get_session),
) -> ListTransactions:
    return ListTransactions(
        transactions=SqlAlchemyTransactionRepository(session),
        sources=SqlAlchemyTransactionSourceRepository(session),
    )


def get_update_transaction_use_case(
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
    ids: SecretsIdGenerator = Depends(get_ids),
) -> UpdateTransaction:
    return UpdateTransaction(
        transactions=SqlAlchemyTransactionRepository(session),
        categories=SqlAlchemyCategoryRepository(session),
        merchant_rules=SqlAlchemyMerchantRuleRepository(session),
        clock=clock,
        ids=ids,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_delete_transaction_use_case(
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
    ids: SecretsIdGenerator = Depends(get_ids),
    events: BusEventPublisher = Depends(get_event_publisher),
) -> DeleteTransaction:
    return DeleteTransaction(
        transactions=SqlAlchemyTransactionRepository(session),
        categories=SqlAlchemyCategoryRepository(session),
        events=events,
        clock=clock,
        ids=ids,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_set_transfer_pair_use_case(
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
) -> SetTransferPair:
    return SetTransferPair(
        transactions=SqlAlchemyTransactionRepository(session),
        sources=SqlAlchemyTransactionSourceRepository(session),
        clock=clock,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_unset_transfer_pair_use_case(
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
) -> UnsetTransferPair:
    return UnsetTransferPair(
        transactions=SqlAlchemyTransactionRepository(session),
        categories=SqlAlchemyCategoryRepository(session),
        sources=SqlAlchemyTransactionSourceRepository(session),
        clock=clock,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_list_categories_use_case(
    session: AsyncSession = Depends(get_session),
) -> ListCategories:
    return ListCategories(categories=SqlAlchemyCategoryRepository(session))


def get_create_category_use_case(
    session: AsyncSession = Depends(get_session),
    ids: SecretsIdGenerator = Depends(get_ids),
) -> CreateCategory:
    return CreateCategory(
        categories=SqlAlchemyCategoryRepository(session),
        ids=ids,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_update_category_use_case(
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
) -> UpdateCategory:
    return UpdateCategory(
        categories=SqlAlchemyCategoryRepository(session),
        transactions=SqlAlchemyTransactionRepository(session),
        clock=clock,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_delete_category_use_case(
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
) -> DeleteCategory:
    return DeleteCategory(
        categories=SqlAlchemyCategoryRepository(session),
        transactions=SqlAlchemyTransactionRepository(session),
        merchant_rules=SqlAlchemyMerchantRuleRepository(session),
        clock=clock,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_list_accounts_use_case(
    session: AsyncSession = Depends(get_session),
) -> ListAccounts:
    return ListAccounts(accounts=SqlAlchemyLinkedAccountRepository(session))


def get_create_account_use_case(
    session: AsyncSession = Depends(get_session),
    ids: SecretsIdGenerator = Depends(get_ids),
) -> CreateAccount:
    return CreateAccount(
        accounts=SqlAlchemyLinkedAccountRepository(session),
        ids=ids,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_update_account_use_case(
    session: AsyncSession = Depends(get_session),
) -> UpdateAccount:
    return UpdateAccount(
        accounts=SqlAlchemyLinkedAccountRepository(session),
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_delete_account_use_case(
    session: AsyncSession = Depends(get_session),
) -> DeleteAccount:
    return DeleteAccount(
        accounts=SqlAlchemyLinkedAccountRepository(session),
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_list_review_use_case(
    session: AsyncSession = Depends(get_session),
) -> ListReview:
    return ListReview(
        review_queue=SqlAlchemyReviewQueueRepository(session),
        review_source=IngestionReviewSource(session),
    )


def get_convert_review_item_use_case(
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
    ids: SecretsIdGenerator = Depends(get_ids),
    events: BusEventPublisher = Depends(get_event_publisher),
) -> ConvertReviewItem:
    create_manual = CreateManualTransaction(
        transactions=SqlAlchemyTransactionRepository(session),
        sources=SqlAlchemyTransactionSourceRepository(session),
        categories=SqlAlchemyCategoryRepository(session),
        accounts=SqlAlchemyLinkedAccountRepository(session),
        events=events,
        clock=clock,
        ids=ids,
        uow=SqlAlchemyUnitOfWork(session),
    )
    get_transaction = GetTransaction(
        transactions=SqlAlchemyTransactionRepository(session),
        sources=SqlAlchemyTransactionSourceRepository(session),
    )
    return ConvertReviewItem(
        review_queue=SqlAlchemyReviewQueueRepository(session),
        review_source=IngestionReviewSource(session),
        create_manual=create_manual,
        get_transaction=get_transaction,
        events=events,
        clock=clock,
        ids=ids,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_discard_review_item_use_case(
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
) -> DiscardReviewItem:
    return DiscardReviewItem(
        review_queue=SqlAlchemyReviewQueueRepository(session),
        review_source=IngestionReviewSource(session),
        clock=clock,
        uow=SqlAlchemyUnitOfWork(session),
    )
