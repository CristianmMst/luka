"""Helper de tests: inserta un `raw_messages` valido (fila padre para las FK de
`transaction_sources`/`review_queue`, spec 004 SS2.7, F2.1).
"""

from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

_RETENTION_DAYS = 90


async def insert_raw_message(  # noqa: PLR0913 - helper de test, un parametro por columna
    session_factory: async_sessionmaker[AsyncSession],
    *,
    user_id: UUID,
    channel: str = "email",
    external_id: str | None = None,
    sender: str = "alertasynotificaciones@an.notificacionesbancolombia.com",
    bank: str | None = "bancolombia",
    body: str | None = (
        "Bancolombia: Compraste $1.000,00 en X con tu T.Deb *1234, el 01/01/2026 a las 10:00."
    ),
    status: str = "pending",
    received_at: datetime | None = None,
) -> UUID:
    """Inserta una fila en `raw_messages` y devuelve su `id`.

    `purge_after` se calcula como `received_at + 90 dias` (spec 004 SS6).
    """
    received = received_at or datetime.now(UTC)
    purge_after = received + timedelta(days=_RETENTION_DAYS)

    async with session_factory() as session:
        result = await session.execute(
            text(
                "INSERT INTO raw_messages "
                "(user_id, channel, external_id, sender, bank, body, status, "
                " received_at, purge_after) "
                "VALUES "
                "(:user_id, :channel, :external_id, :sender, :bank, :body, :status, "
                " :received_at, :purge_after) "
                "RETURNING id"
            ),
            {
                "user_id": user_id,
                "channel": channel,
                "external_id": external_id or str(uuid4()),
                "sender": sender,
                "bank": bank,
                "body": body,
                "status": status,
                "received_at": received,
                "purge_after": purge_after,
            },
        )
        raw_message_id: UUID = result.scalar_one()
        await session.commit()

    return raw_message_id
