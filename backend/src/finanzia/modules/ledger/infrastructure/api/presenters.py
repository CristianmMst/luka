"""Construccion de respuestas HTTP a partir de entidades de dominio (controller ruling 2).

Separado de `schemas.py` (que solo declara los modelos Pydantic) para mantener ese
modulo por debajo de ~200 lineas (guia de organizacion de codigo de la tarea).
"""

from decimal import Decimal
from typing import Any

from finanzia.modules.ledger.application.dto import ReviewEntry, TransactionDetail
from finanzia.modules.ledger.domain.entities import Category, LinkedAccount, Transaction
from finanzia.modules.ledger.domain.review import ReviewItem
from finanzia.modules.ledger.infrastructure.api.schemas import (
    AccountResponse,
    CategoryResponse,
    DiscardReviewResponse,
    ReviewEntryResponse,
    TransactionListItem,
    TransactionResponse,
    TransactionSourceResponse,
    TransactionSummary,
)

_CENTS = Decimal("0.01")


def _amount_str(amount: Decimal) -> str:
    """Formatea un monto como cadena decimal con exactamente 2 decimales."""
    return str(amount.quantize(_CENTS))


def _list_item_fields(tx: Transaction) -> dict[str, Any]:
    """Campos comunes a `TransactionListItem` y `TransactionResponse`."""
    return {
        "id": tx.id,
        "amount": _amount_str(tx.amount),
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
        "parsed_by": tx.parsed_by,
        "confidence": tx.confidence,
        "notes": tx.notes,
        "created_at": tx.created_at,
        "updated_at": tx.updated_at,
    }


def transaction_list_item(tx: Transaction) -> TransactionListItem:
    """Item de `GET /transactions`: sin `sources`/`pair` (spec 005 SS6, RNF-3).

    Se construye directo desde la entidad devuelta por `ListTransactions`, sin
    ninguna consulta adicional (nada de `sources`/pareja por fila).
    """
    return TransactionListItem(**_list_item_fields(tx))


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
        **_list_item_fields(tx),
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


def review_entry_response(entry: ReviewEntry) -> ReviewEntryResponse | None:
    """Construye el item de `GET /review`; `None` si el `raw_message` ya no existe
    (`entry.source is None`, caso defensivo: el FK es CASCADE, no deberia ocurrir).
    """
    source = entry.source
    if source is None:
        return None
    item = entry.item
    return ReviewEntryResponse(
        raw_message_id=item.raw_message_id,
        channel=source.channel.value,
        bank=source.bank.value if source.bank is not None else None,
        sender=source.sender,
        received_at=source.received_at,
        reason=item.reason.value,
        partial_extract=dict(item.partial_extract),
        text=source.text,
        created_at=item.created_at,
    )


def discard_review_response(item: ReviewItem) -> DiscardReviewResponse:
    """Construye la respuesta de `POST /review/{raw_message_id}/discard`."""
    resolved_at = item.resolved_at
    resolution = item.resolution
    if resolved_at is None or resolution is None:
        raise RuntimeError("item de revision sin resolver")
    return DiscardReviewResponse(
        raw_message_id=item.raw_message_id,
        resolution=resolution.value,
        resolved_at=resolved_at,
    )
