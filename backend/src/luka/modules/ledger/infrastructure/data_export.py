"""Exportacion de los datos de ledger de un usuario (RF-11.2, spec 005 SS2).

Lectura directa de las tablas del modulo, sin pasar por los repositorios de
dominio: es un volcado de solo lectura, en tipos JSON (ids y montos como
texto, fechas ISO 8601). Solo filas de `user_id`; las categorias del sistema
no se exportan (no son del usuario), pero los movimientos llevan su nombre.
"""

from __future__ import annotations

from collections import defaultdict
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import select

from luka.modules.ledger.infrastructure.orm import (
    CategoryRow,
    LinkedAccountRow,
    MerchantRuleRow,
    ReviewQueueRow,
    TransactionRow,
    TransactionSourceRow,
)

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession


def _iso(value: datetime | None) -> str | None:
    return value.isoformat() if value is not None else None


def _str(value: UUID | Decimal | None) -> str | None:
    return str(value) if value is not None else None


async def export_ledger_data(session: AsyncSession, user_id: UUID) -> dict[str, object]:
    """Cuentas, categorias propias, movimientos con sus fuentes, reglas de
    comercio e items de revision de `user_id`."""
    accounts = (
        await session.execute(
            select(LinkedAccountRow)
            .where(LinkedAccountRow.user_id == user_id)
            .order_by(LinkedAccountRow.created_at)
        )
    ).scalars()
    categories = (
        await session.execute(
            select(CategoryRow).where(
                (CategoryRow.user_id == user_id) | CategoryRow.user_id.is_(None)
            )
        )
    ).scalars()
    category_names: dict[UUID, str] = {}
    own_categories: list[dict[str, object]] = []
    for category in categories:
        category_names[category.id] = category.name
        if category.user_id == user_id:
            own_categories.append(
                {
                    "id": _str(category.id),
                    "name": category.name,
                    "icon": category.icon,
                    "color": category.color,
                    "fiscal_tag": category.fiscal_tag,
                }
            )

    transactions = list(
        (
            await session.execute(
                select(TransactionRow)
                .where(TransactionRow.user_id == user_id)
                .order_by(TransactionRow.occurred_at)
            )
        ).scalars()
    )
    sources: dict[UUID, list[dict[str, object]]] = defaultdict(list)
    if transactions:
        rows = (
            await session.execute(
                select(TransactionSourceRow).where(
                    TransactionSourceRow.transaction_id.in_([t.id for t in transactions])
                )
            )
        ).scalars()
        for source in rows:
            sources[source.transaction_id].append(
                {
                    "channel": source.channel,
                    "received_at": _iso(source.received_at),
                }
            )

    rules = (
        await session.execute(select(MerchantRuleRow).where(MerchantRuleRow.user_id == user_id))
    ).scalars()
    review = (
        await session.execute(
            select(ReviewQueueRow)
            .where(ReviewQueueRow.user_id == user_id)
            .order_by(ReviewQueueRow.created_at)
        )
    ).scalars()

    return {
        "accounts": [
            {
                "id": _str(a.id),
                "bank": a.bank,
                "kind": a.kind,
                "last4": a.last4,
                "alias": a.alias,
            }
            for a in accounts
        ],
        "categories": own_categories,
        "transactions": [
            {
                "id": _str(t.id),
                "occurred_at": _iso(t.occurred_at),
                "amount": _str(t.amount),
                "currency": t.currency,
                "direction": t.direction,
                "kind": t.kind,
                "merchant": t.merchant,
                "description": t.description,
                "bank": t.bank,
                "account_id": _str(t.account_id),
                "category": category_names.get(t.category_id),
                "fiscal_tag": t.fiscal_tag,
                "transfer_pair_id": _str(t.transfer_pair_id),
                "parsed_by": t.parsed_by,
                "notes": t.notes,
                "sources": sources.get(t.id, []),
                "created_at": _iso(t.created_at),
                "updated_at": _iso(t.updated_at),
            }
            for t in transactions
        ],
        "merchant_rules": [
            {
                "merchant_pattern": r.merchant_pattern,
                "category": category_names.get(r.category_id),
            }
            for r in rules
        ],
        "review_items": [
            {
                "reason": item.reason,
                "created_at": _iso(item.created_at),
                "resolution": item.resolution,
                "resolved_at": _iso(item.resolved_at),
            }
            for item in review
        ],
    }


__all__ = ["export_ledger_data"]
