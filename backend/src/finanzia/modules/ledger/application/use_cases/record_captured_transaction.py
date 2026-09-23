"""Caso de uso: registrar una transaccion capturada (spec 004 SS3, AC-5.1/5.2/5.3)."""

from dataclasses import replace
from uuid import UUID

from finanzia.modules.ledger.application.dto import CapturedTransactionCommand, Recorded
from finanzia.modules.ledger.application.ports import (
    CategoryRepositoryPort,
    ClockPort,
    EventPublisherPort,
    IdGeneratorPort,
    LinkedAccountRepositoryPort,
    MerchantRuleRepositoryPort,
    TransactionRepositoryPort,
    TransactionSourceRepositoryPort,
    UnitOfWorkPort,
)
from finanzia.modules.ledger.application.use_cases._transfer_matching import try_auto_pair
from finanzia.modules.ledger.domain.dedupe import candidate_keys, is_same_capture
from finanzia.modules.ledger.domain.entities import (
    Category,
    TransactionSource,
    new_captured_transaction,
)
from finanzia.modules.ledger.domain.errors import CategoryNotFound, LedgerError
from finanzia.modules.ledger.domain.merchant import match_rule, normalize_merchant
from finanzia.modules.ledger.events import TransactionCaptured


class RecordCapturedTransaction:
    """Aplica dedupe (spec 004 SS3), clasificacion (spec 006 SS4.3) y matcher (SS4)."""

    def __init__(  # noqa: PLR0913 - un puerto por dependencia externa
        self,
        *,
        transactions: TransactionRepositoryPort,
        sources: TransactionSourceRepositoryPort,
        categories: CategoryRepositoryPort,
        accounts: LinkedAccountRepositoryPort,
        merchant_rules: MerchantRuleRepositoryPort,
        events: EventPublisherPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._transactions = transactions
        self._sources = sources
        self._categories = categories
        self._accounts = accounts
        self._merchant_rules = merchant_rules
        self._events = events
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(self, cmd: CapturedTransactionCommand) -> Recorded:
        """Deduplica, clasifica, inserta y empareja (si aplica) la captura entrante."""
        keys = candidate_keys(
            user_id=cmd.user_id,
            bank=cmd.bank,
            amount=cmd.amount,
            direction=cmd.direction,
            occurred_at=cmd.occurred_at,
            last4=cmd.last4,
        )

        existing_candidates = await self._transactions.find_by_dedupe_keys(cmd.user_id, keys)
        existing = [
            t for t in existing_candidates if is_same_capture(t.occurred_at, cmd.occurred_at)
        ]
        if existing:
            target = min(existing, key=lambda t: t.created_at)
            attached = await self._attach_source(target.id, cmd)
            if attached:
                target = replace(target, updated_at=self._clock.now())
                await self._transactions.update(target)
            await self._uow.commit()
            return Recorded(transaction=target, created=False, source_attached=attached)

        category = await self._resolve_category(
            cmd.user_id, cmd.merchant, cmd.suggested_category_slug
        )
        account = None
        if cmd.last4:
            account = await self._accounts.find_by_bank_last4(cmd.user_id, cmd.bank, cmd.last4)

        tx = new_captured_transaction(
            id=self._ids.new_id(),
            user_id=cmd.user_id,
            amount=cmd.amount,
            direction=cmd.direction,
            occurred_at=cmd.occurred_at,
            category=category,
            now=self._clock.now(),
            bank=cmd.bank,
            last4=cmd.last4,
            merchant=cmd.merchant,
            description=cmd.description,
            account_id=account.id if account is not None else None,
            parsed_by=cmd.parsed_by,
            confidence=cmd.confidence,
            dedupe_key=keys[1],
        )
        inserted_id = await self._transactions.insert_if_absent(tx)
        if inserted_id is None:
            # Carrera: otro proceso inserto la misma clave canonica primero.
            reread = await self._transactions.find_by_dedupe_keys(cmd.user_id, [keys[1]])
            if not reread:
                raise LedgerError("carrera de insercion sin fila resultante")
            target = reread[0]
            attached = await self._attach_source(target.id, cmd)
            if attached:
                target = replace(target, updated_at=self._clock.now())
                await self._transactions.update(target)
            await self._uow.commit()
            return Recorded(transaction=target, created=False, source_attached=attached)

        await self._attach_source(tx.id, cmd)
        tx = await try_auto_pair(tx, transactions=self._transactions, clock=self._clock)

        await self._uow.commit()
        await self._events.publish(
            TransactionCaptured(
                event_id=self._ids.new_id(),
                occurred_at=self._clock.now(),
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
        return Recorded(transaction=tx, created=True, source_attached=True)

    async def _attach_source(self, transaction_id: UUID, cmd: CapturedTransactionCommand) -> bool:
        source = TransactionSource(
            id=self._ids.new_id(),
            transaction_id=transaction_id,
            raw_message_id=cmd.source.raw_message_id,
            channel=cmd.source.channel,
            received_at=cmd.source.received_at,
        )
        return await self._sources.attach(source)

    async def _resolve_category(
        self, user_id: UUID, merchant: str | None, suggested_slug: str | None
    ) -> Category:
        """Regla de comercio aprendida -> sugerencia del parser -> `sin_categoria` (006 SS4.3)."""
        rules = await self._merchant_rules.list_for_user(user_id)
        rule = match_rule(normalize_merchant(merchant), rules)
        if rule is not None:
            category = await self._categories.get_visible(user_id, rule.category_id)
            if category is not None:
                return category
        if suggested_slug:
            category = await self._categories.get_system_by_slug(suggested_slug)
            if category is not None:
                return category
        category = await self._categories.get_system_by_slug("sin_categoria")
        if category is None:
            raise CategoryNotFound
        return category
