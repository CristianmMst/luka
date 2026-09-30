"""Generador de ids de recurring (`IdGeneratorPort`)."""

import uuid


class UuidGenerator:
    """Ids `uuid4` para gastos fijos y ocurrencias."""

    def new_id(self) -> uuid.UUID:
        return uuid.uuid4()
