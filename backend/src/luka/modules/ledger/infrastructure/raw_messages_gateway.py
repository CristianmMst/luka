"""Adaptador de `ReviewSourcePort` sobre `ingestion.public` (D1, R4).

Unico punto (junto con `infrastructure/consumers.py`, que cruza a
`parsing.events`) donde `ledger` depende de otro modulo salvo
`identity.public` (`infrastructure/api/deps.py`): R2 prohibe que la capa
`application` importe `public.py` de otro modulo, asi que el cruce vive aqui,
en `infrastructure`.
"""

from __future__ import annotations

from collections.abc import Sequence
from datetime import datetime
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.ingestion.public import load_raw_messages_for_review, mark_raw_message
from luka.modules.ledger.application.dto import ReviewSourceView
from luka.modules.ledger.domain.enums import Bank, Channel


def _bank(value: str | None) -> Bank | None:
    """`None` se preserva; un valor desconocido cae a `Bank.OTHER` (D1)."""
    if value is None:
        return None
    try:
        return Bank(value)
    except ValueError:
        return Bank.OTHER


class IngestionReviewSource:
    """Implementacion de `ReviewSourcePort` delegando en `ingestion.public`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def load_views(self, user_id: UUID, ids: Sequence[UUID]) -> dict[UUID, ReviewSourceView]:
        views = await load_raw_messages_for_review(self._session, user_id, ids)
        return {
            raw_id: ReviewSourceView(
                raw_message_id=view.id,
                channel=Channel(view.channel.value),
                bank=_bank(view.bank),
                sender=view.sender,
                text=view.body,
                received_at=view.received_at,
            )
            for raw_id, view in views.items()
        }

    async def mark_status(self, raw_message_id: UUID, status: str, now: datetime) -> bool:
        return await mark_raw_message(self._session, raw_message_id, status, now)


__all__ = ["IngestionReviewSource"]
