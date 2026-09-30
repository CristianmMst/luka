"""Generador de identificadores y aleatoriedad para claves manuales (spec 004 SS3)."""

import secrets
import uuid


class SecretsIdGenerator:
    """Implementacion de `IdGeneratorPort` basada en `secrets`/`uuid`."""

    def new_id(self) -> uuid.UUID:
        return uuid.uuid4()

    def random_hex(self, n_bytes: int) -> str:
        return secrets.token_hex(n_bytes)
