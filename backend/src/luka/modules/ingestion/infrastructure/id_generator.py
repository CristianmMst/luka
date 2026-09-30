"""Generador de identificadores para ingestion (spec 004 §2.7)."""

import uuid


class SecretsIdGenerator:
    """Implementacion de `IdGeneratorPort` basada en `uuid.uuid4`."""

    def new_id(self) -> uuid.UUID:
        return uuid.uuid4()


__all__ = ["SecretsIdGenerator"]
