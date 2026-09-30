"""Mappers fila (ORM) <-> entidad de dominio para identity (spec 004 SS2.1-2.2)."""

from collections.abc import Mapping
from datetime import UTC, datetime

from luka.modules.identity.domain.entities import RefreshToken, User, UserStatus
from luka.modules.identity.infrastructure.orm import RefreshTokenRow, UserRow


def _consents_from_json(raw: Mapping[str, object]) -> Mapping[str, datetime]:
    """Decodifica el JSONB `{tipo: iso-timestamp}` a `Mapping[str, datetime]`."""
    return {tipo: datetime.fromisoformat(str(valor)) for tipo, valor in raw.items()}


def _consents_to_json(consents: Mapping[str, datetime]) -> dict[str, str]:
    """Codifica `Mapping[str, datetime]` al JSONB `{tipo: iso-timestamp}`."""
    return {tipo: valor.astimezone(UTC).isoformat() for tipo, valor in consents.items()}


def user_row_to_entity(row: UserRow) -> User:
    """Convierte una fila `UserRow` en la entidad de dominio `User`."""
    return User(
        id=row.id,
        google_sub=row.google_sub,
        email=row.email,
        display_name=row.display_name,
        photo_url=row.photo_url,
        status=UserStatus(row.status),
        consents=_consents_from_json(row.consents),
        created_at=row.created_at,
        updated_at=row.updated_at,
    )


def user_entity_to_row(user: User) -> UserRow:
    """Construye una fila `UserRow` nueva a partir de la entidad `User`."""
    return UserRow(
        id=user.id,
        google_sub=user.google_sub,
        email=user.email,
        display_name=user.display_name,
        photo_url=user.photo_url,
        status=user.status.value,
        consents=_consents_to_json(user.consents),
        created_at=user.created_at,
        updated_at=user.updated_at,
    )


def refresh_token_row_to_entity(row: RefreshTokenRow) -> RefreshToken:
    """Convierte una fila `RefreshTokenRow` en la entidad de dominio `RefreshToken`."""
    return RefreshToken(
        id=row.id,
        user_id=row.user_id,
        token_hash=row.token_hash,
        family_id=row.family_id,
        expires_at=row.expires_at,
        revoked_at=row.revoked_at,
        device_info=row.device_info,
        created_at=row.created_at,
    )


def refresh_token_entity_to_row(token: RefreshToken) -> RefreshTokenRow:
    """Construye una fila `RefreshTokenRow` nueva a partir de la entidad `RefreshToken`."""
    return RefreshTokenRow(
        id=token.id,
        user_id=token.user_id,
        token_hash=token.token_hash,
        family_id=token.family_id,
        expires_at=token.expires_at,
        revoked_at=token.revoked_at,
        device_info=token.device_info,
        created_at=token.created_at,
    )
