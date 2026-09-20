"""Doble de sesion autenticada para tests de integracion (login real via API)."""

from dataclasses import dataclass
from uuid import UUID


@dataclass(frozen=True, slots=True)
class AuthedUser:
    """Resultado de loguear un usuario de prueba a traves de la API real."""

    id: UUID
    email: str
    access_token: str
    refresh_token: str

    @property
    def headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self.access_token}"}
