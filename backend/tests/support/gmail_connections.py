"""Helper de tests: inserta una `gmail_connections` valida (spec 004 §2.3, F3.2)."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker


async def insert_gmail_connection(  # noqa: PLR0913 - helper de test, un parametro por columna
    session_factory: async_sessionmaker[AsyncSession],
    *,
    user_id: UUID,
    email: str = "ana@example.com",
    refresh_token_enc: bytes = b"nonce-de-12-bytes+ciphertext-de-prueba",
    history_id: int | None = None,
    watch_expires_at: datetime | None = None,
    status: str = "active",
    last_sync_at: datetime | None = None,
) -> None:
    """Inserta una fila en `gmail_connections` para `user_id`."""
    async with session_factory() as session:
        await session.execute(
            text(
                "INSERT INTO gmail_connections "
                "(user_id, email, refresh_token_enc, history_id, watch_expires_at, "
                " status, last_sync_at) "
                "VALUES "
                "(:user_id, :email, :refresh_token_enc, :history_id, :watch_expires_at, "
                " :status, :last_sync_at)"
            ),
            {
                "user_id": user_id,
                "email": email,
                "refresh_token_enc": refresh_token_enc,
                "history_id": history_id,
                "watch_expires_at": watch_expires_at,
                "status": status,
                "last_sync_at": last_sync_at,
            },
        )
        await session.commit()
