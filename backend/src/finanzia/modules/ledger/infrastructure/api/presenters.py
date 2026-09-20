"""Construccion de respuestas HTTP a partir de entidades de dominio (controller ruling 2).

Separado de `schemas.py` (que solo declara los modelos Pydantic) para mantener ese
modulo por debajo de ~200 lineas (guia de organizacion de codigo de la tarea).
"""

from decimal import Decimal

from finanzia.modules.ledger.application.dto import TransactionDetail
from finanzia.modules.ledger.domain.entities import Category, LinkedAccount, Transaction
from finanzia.modules.ledger.infrastructure.api.schemas import (
    AccountResponse,
    CategoryResponse,
    TransactionResponse,
    TransactionSourceResponse,
    TransactionSummary,
)

_CENTS = Decimal("0.01")


def _amount_str(amount: Decimal) -> str:
    """Formatea un monto como cadena decimal con exactamente 2 decimales."""
    return str(amount.quantize(_CENTS))


def transaction_summary(tx: Transaction) -> TransactionSummary:
    """Construye el resumen usado como `pair` dentro de `TransactionResponse`."""
    return TransactionSummary(
        id=tx.id,
        amount=_amount_str(tx.amount),
        direction=tx.direction.value,
        kind=tx.kind.value,
        occurred_at=tx.occurred_at,
        merchant=tx.merchant,
        bank=tx.bank.value if tx.bank is not None else None,
        account_id=tx.account_id,
        category_id=tx.category_id,
        fiscal_tag=tx.fiscal_tag.value,
    )


def transaction_response(detail: TransactionDetail) -> TransactionResponse:
    """Construye la respuesta completa de una transaccion (spec 005 SS6, SS9.3)."""
    tx = detail.transaction
    return TransactionResponse(
        id=tx.id,
        amount=_amount_str(tx.amount),
        currency=tx.currency,
        direction=tx.direction.value,
        kind=tx.kind.value,
        occurred_at=tx.occurred_at,
        merchant=tx.merchant,
        description=tx.description,
        bank=tx.bank.value if tx.bank is not None else None,
        account_id=tx.account_id,
        category_id=tx.category_id,
        fiscal_tag=tx.fiscal_tag.value,
        transfer_pair_id=tx.transfer_pair_id,
        transfer_auto=tx.transfer_auto,
        parsed_by=tx.parsed_by,
        confidence=tx.confidence,
        notes=tx.notes,
        created_at=tx.created_at,
        updated_at=tx.updated_at,
        sources=[
            TransactionSourceResponse(
                id=source.id,
                channel=source.channel.value,
                raw_message_id=source.raw_message_id,
                received_at=source.received_at,
            )
            for source in detail.sources
        ],
        pair=transaction_summary(detail.pair) if detail.pair is not None else None,
    )


def category_response(category: Category) -> CategoryResponse:
    """Construye la respuesta publica de una categoria (spec 005 SS7)."""
    return CategoryResponse(
        id=category.id,
        user_id=category.user_id,
        slug=category.slug,
        name=category.name,
        icon=category.icon,
        color=category.color,
        fiscal_tag=category.fiscal_tag.value,
        is_system=category.is_system,
    )


def account_response(account: LinkedAccount) -> AccountResponse:
    """Construye la respuesta publica de una cuenta vinculada (spec 005 SS7)."""
    return AccountResponse(
        id=account.id,
        bank=account.bank.value,
        kind=account.kind.value,
        last4=account.last4,
        alias=account.alias,
    )
