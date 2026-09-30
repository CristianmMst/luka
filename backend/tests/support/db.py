"""Limpieza de las tablas de usuario compartida por la fixture `db_clean` y por
los tests que necesitan invocarla explicitamente (spec 004 §2.1-2.10, F2.1).

Vive aqui (y no dentro de `conftest.py`) para que un test pueda ejercitar la
MISMA limpieza que corre entre tests sin depender del orden de ejecucion.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import text

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

#: Orden: hijos del ledger antes que sus padres, `raw_messages` (ingestion) antes
#: que `users`. `review_queue` referencia `raw_messages` por PK/FK CASCADE, pero se
#: borra explicito primero por claridad. `categories` nunca se trunca completa:
#: solo se borran las categorias de usuario (`user_id IS NOT NULL`) para preservar
#: el seed de las 24 categorias del sistema.
_DELETES = (
    "DELETE FROM device_tokens",
    "DELETE FROM recurring_match_rejections",
    "DELETE FROM recurring_occurrences",
    "DELETE FROM recurring_expenses",
    "DELETE FROM review_queue",
    "DELETE FROM merchant_rules",
    "DELETE FROM transaction_sources",
    "DELETE FROM transactions",
    "DELETE FROM linked_accounts",
    "DELETE FROM categories WHERE user_id IS NOT NULL",
    "DELETE FROM raw_messages",
    "DELETE FROM gmail_connections",
    "DELETE FROM refresh_tokens",
    "DELETE FROM users",
)


async def clean_user_tables(session_factory: async_sessionmaker[AsyncSession]) -> None:
    """Vacia las tablas de usuario (todo salvo el seed del sistema)."""
    async with session_factory() as session:
        for statement in _DELETES:
            await session.execute(text(statement))
        await session.commit()


__all__ = ["clean_user_tables"]
