"""Mappers fila (ORM) <-> entidad de dominio para ledger (spec 004 SS2.4-2.9)."""

from typing import Any
from uuid import UUID

from finanzia.modules.ledger.domain.entities import (
    Category,
    LinkedAccount,
    MerchantRule,
    Transaction,
    TransactionSource,
)
from finanzia.modules.ledger.domain.enums import (
    AccountKind,
    Bank,
    Channel,
    Direction,
    FiscalTag,
    Kind,
)
from finanzia.modules.ledger.infrastructure.orm import (
    CategoryRow,
    LinkedAccountRow,
    MerchantRuleRow,
    TransactionRow,
    TransactionSourceRow,
)


def transaction_row_to_entity(row: TransactionRow) -> Transaction:
    """Convierte una fila `TransactionRow` en la entidad de dominio `Transaction`."""
    return Transaction(
        id=row.id,
        user_id=row.user_id,
        amount=row.amount,
        currency=row.currency,
        direction=Direction(row.direction),
        kind=Kind(row.kind),
        occurred_at=row.occurred_at,
        merchant=row.merchant,
        description=row.description,
        bank=Bank(row.bank) if row.bank is not None else None,
        account_id=row.account_id,
        category_id=row.category_id,
        fiscal_tag=FiscalTag(row.fiscal_tag),
        transfer_pair_id=row.transfer_pair_id,
        transfer_auto=row.transfer_auto,
        transfer_exclusions=frozenset(UUID(str(v)) for v in row.transfer_exclusions),
        dedupe_key=row.dedupe_key,
        parsed_by=row.parsed_by,
        confidence=row.confidence,
        notes=row.notes,
        created_at=row.created_at,
        updated_at=row.updated_at,
    )


def transaction_entity_to_values(tx: Transaction) -> dict[str, Any]:
    """Construye el diccionario de columnas de `TransactionRow` a partir de `tx`.

    Se usa tanto para `INSERT` (via `pg_insert(...).values(**values)`) como para
    reconstruir el `UPDATE` de fila completa (ruling 1): `id`/`user_id` quedan
    incluidos porque el `INSERT` los necesita; `update()` los excluye del `SET`.
    """
    return {
        "id": tx.id,
        "user_id": tx.user_id,
        "amount": tx.amount,
        "currency": tx.currency,
        "direction": tx.direction.value,
        "kind": tx.kind.value,
        "occurred_at": tx.occurred_at,
        "merchant": tx.merchant,
        "description": tx.description,
        "bank": tx.bank.value if tx.bank is not None else None,
        "account_id": tx.account_id,
        "category_id": tx.category_id,
        "fiscal_tag": tx.fiscal_tag.value,
        "transfer_pair_id": tx.transfer_pair_id,
        "transfer_auto": tx.transfer_auto,
        "transfer_exclusions": [str(v) for v in tx.transfer_exclusions],
        "dedupe_key": tx.dedupe_key,
        "parsed_by": tx.parsed_by,
        "confidence": tx.confidence,
        "notes": tx.notes,
        "created_at": tx.created_at,
        "updated_at": tx.updated_at,
    }


def source_row_to_entity(row: TransactionSourceRow) -> TransactionSource:
    """Convierte una fila `TransactionSourceRow` en la entidad `TransactionSource`."""
    return TransactionSource(
        id=row.id,
        transaction_id=row.transaction_id,
        raw_message_id=row.raw_message_id,
        channel=Channel(row.channel),
        received_at=row.received_at,
    )


def source_entity_to_values(source: TransactionSource) -> dict[str, Any]:
    """Construye el diccionario de columnas de `TransactionSourceRow` a partir de `source`."""
    return {
        "id": source.id,
        "transaction_id": source.transaction_id,
        "raw_message_id": source.raw_message_id,
        "channel": source.channel.value,
        "received_at": source.received_at,
    }


def category_row_to_entity(row: CategoryRow) -> Category:
    """Convierte una fila `CategoryRow` en la entidad de dominio `Category`."""
    return Category(
        id=row.id,
        user_id=row.user_id,
        slug=row.slug,
        name=row.name,
        icon=row.icon,
        color=row.color,
        fiscal_tag=FiscalTag(row.fiscal_tag),
    )


def category_entity_to_row(category: Category) -> CategoryRow:
    """Construye una fila `CategoryRow` nueva a partir de la entidad `Category`."""
    return CategoryRow(
        id=category.id,
        user_id=category.user_id,
        slug=category.slug,
        name=category.name,
        icon=category.icon,
        color=category.color,
        fiscal_tag=category.fiscal_tag.value,
    )


def account_row_to_entity(row: LinkedAccountRow) -> LinkedAccount:
    """Convierte una fila `LinkedAccountRow` en la entidad de dominio `LinkedAccount`."""
    return LinkedAccount(
        id=row.id,
        user_id=row.user_id,
        bank=Bank(row.bank),
        kind=AccountKind(row.kind),
        last4=row.last4,
        alias=row.alias,
    )


def account_entity_to_row(account: LinkedAccount) -> LinkedAccountRow:
    """Construye una fila `LinkedAccountRow` nueva a partir de la entidad `LinkedAccount`."""
    return LinkedAccountRow(
        id=account.id,
        user_id=account.user_id,
        bank=account.bank.value,
        kind=account.kind.value,
        last4=account.last4,
        alias=account.alias,
    )


def merchant_rule_row_to_entity(row: MerchantRuleRow) -> MerchantRule:
    """Convierte una fila `MerchantRuleRow` en la entidad de dominio `MerchantRule`."""
    return MerchantRule(
        id=row.id,
        user_id=row.user_id,
        merchant_pattern=row.merchant_pattern,
        category_id=row.category_id,
    )
