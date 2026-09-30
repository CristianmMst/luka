"""Mappers fila (ORM) <-> entidad de dominio para ingestion (spec 004 §2.3, §2.7)."""

from typing import Any

from luka.modules.ingestion.domain.entities import GmailConnection, RawMessage
from luka.modules.ingestion.domain.enums import Channel, GmailConnectionStatus, RawMessageStatus
from luka.modules.ingestion.infrastructure.orm import GmailConnectionRow, RawMessageRow


def raw_message_row_to_entity(row: RawMessageRow) -> RawMessage:
    """Convierte una fila `RawMessageRow` en la entidad de dominio `RawMessage`."""
    return RawMessage(
        id=row.id,
        user_id=row.user_id,
        channel=Channel(row.channel),
        external_id=row.external_id,
        sender=row.sender,
        bank=row.bank,
        body=row.body,
        status=RawMessageStatus(row.status),
        received_at=row.received_at,
        purge_after=row.purge_after,
        requeue_attempts=row.requeue_attempts,
    )


def raw_message_entity_to_values(msg: RawMessage) -> dict[str, Any]:
    """Construye el diccionario de columnas de `RawMessageRow` a partir de `msg`."""
    return {
        "id": msg.id,
        "user_id": msg.user_id,
        "channel": msg.channel.value,
        "external_id": msg.external_id,
        "sender": msg.sender,
        "bank": msg.bank,
        "body": msg.body,
        "status": msg.status.value,
        "received_at": msg.received_at,
        "purge_after": msg.purge_after,
        "requeue_attempts": msg.requeue_attempts,
    }


def gmail_connection_row_to_entity(row: GmailConnectionRow) -> GmailConnection:
    """Convierte una fila `GmailConnectionRow` en la entidad `GmailConnection`."""
    return GmailConnection(
        user_id=row.user_id,
        email=row.email,
        refresh_token_enc=row.refresh_token_enc,
        history_id=row.history_id,
        watch_expires_at=row.watch_expires_at,
        status=GmailConnectionStatus(row.status),
        last_sync_at=row.last_sync_at,
        created_at=row.created_at,
        updated_at=row.updated_at,
    )


def gmail_connection_entity_to_values(connection: GmailConnection) -> dict[str, Any]:
    """Construye el diccionario de columnas de `GmailConnectionRow` a partir de `connection`."""
    return {
        "user_id": connection.user_id,
        "email": connection.email,
        "refresh_token_enc": connection.refresh_token_enc,
        "history_id": connection.history_id,
        "watch_expires_at": connection.watch_expires_at,
        "status": connection.status.value,
        "last_sync_at": connection.last_sync_at,
        "created_at": connection.created_at,
        "updated_at": connection.updated_at,
    }


__all__ = [
    "gmail_connection_entity_to_values",
    "gmail_connection_row_to_entity",
    "raw_message_entity_to_values",
    "raw_message_row_to_entity",
]
