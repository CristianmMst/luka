"""Caso de uso: crear una transaccion manual (spec 004 SS2.6, AC-6.4)."""

from finanzia.modules.ledger.application.dto import ManualTransactionCommand
from finanzia.modules.ledger.application.ports import (
    CategoryRepositoryPort,
    ClockPort,
    EventPublisherPort,
    IdGeneratorPort,
    LinkedAccountRepositoryPort,
    TransactionRepositoryPort,
    TransactionSourceRepositoryPort,
    UnitOfWorkPort,
)
from finanzia.modules.ledger.application.use_cases._transfer_matching import try_auto_pair
from finanzia.modules.ledger.domain.dedupe import manual_dedupe_key
from finanzia.modules.ledger.domain.entities import (
    Transaction,
    TransactionSource,
    new_manual_transaction,
)
from finanzia.modules.ledger.domain.enums import Kind
from finanzia.modules.ledger.domain.errors import AccountNotFound, CategoryNotFound, LedgerError
from finanzia.modules.ledger.events import TransactionCaptured

_MANUAL_DEDUPE_HEX_BYTES = 16


class CreateManualTransaction:
    """Registra una transaccion capturada a mano por el usuario (spec 004 SS2.6)."""

    def __init__(  # noqa: PLR0913 - un puerto por dependencia externa
        self,
        *,
        transactions: TransactionRepositoryPort,
        sources: TransactionSourceRepositoryPort,
        categories: CategoryRepositoryPort,
        accounts: LinkedAccountRepositoryPort,
        events: EventPublisherPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._transactions = transactions
        self._sources = sources
        self._categories = categories
        self._accounts = accounts
        self._events = events
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(self, cmd: ManualTransactionCommand) -> Transaction:
        """Valida categoria/cuenta propias, inserta, corre el matcher y publica el evento."""
        if cmd.category_id is not None:
            category = await self._categories.get_visible(cmd.user_id, cmd.category_id)
            if category is None:
                raise CategoryNotFound
        else:
            category = await self._categories.get_system_by_slug("sin_categoria")
            if category is None:
                raise CategoryNotFound

        account = None
        if cmd.account_id is not None:
            account = await self._accounts.get(cmd.user_id, cmd.account_id)
            if account is None:
                raise AccountNotFound

        now = self._clock.now()
        dedupe_key = manual_dedupe_key(self._ids.random_hex(_MANUAL_DEDUPE_HEX_BYTES))
        tx = new_manual_transaction(
            id=self._ids.new_id(),
            user_id=cmd.user_id,
            amount=cmd.amount,
            direction=cmd.direction,
            occurred_at=cmd.occurred_at,
            category=category,
            now=now,
            dedupe_key=dedupe_key,
            merchant=cmd.merchant,
            description=cmd.description,
            bank=account.bank if account is not None else None,
            account_id=cmd.account_id,
            notes=cmd.notes,
            kind=cmd.kind,
        )
        inserted_id = await self._transactions.insert_if_absent(tx)
        if inserted_id is None:
            raise LedgerError("colision inesperada de dedupe_key manual")

        await self._sources.attach(
            TransactionSource(
                id=self._ids.new_id(),
                transaction_id=tx.id,
                raw_message_id=None,
                channel=cmd.channel,
                received_at=now,
            )
        )

        if tx.account_id is not None and tx.kind != Kind.TRANSFER:
            tx = await try_auto_pair(tx, transactions=self._transactions, clock=self._clock)

        await self._uow.commit()
        await self._events.publish(
            TransactionCaptured(
                event_id=self._ids.new_id(),
                occurred_at=now,
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
        return tx
