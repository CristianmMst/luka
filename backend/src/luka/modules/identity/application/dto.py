"""DTOs de salida de los casos de uso de identity."""

from collections.abc import Mapping
from dataclasses import dataclass

from luka.modules.identity.domain.entities import User


@dataclass(frozen=True, slots=True)
class SessionResult:
    """Resultado de login/refresh: par de tokens y el usuario asociado."""

    access_token: str
    refresh_token: str
    expires_in: int
    user: User


@dataclass(frozen=True, slots=True)
class MeResult:
    """Perfil del usuario autenticado, con el estado de sus conexiones externas."""

    user: User
    connections: Mapping[str, str]


def build_connections(user: User, gmail_status: str) -> Mapping[str, str]:
    """Mapa de conexiones: Gmail segun ingestion, notificaciones segun los consentimientos."""
    return {
        "gmail": gmail_status,
        "notifications": "granted" if "notifications" in user.consents else "none",
    }
