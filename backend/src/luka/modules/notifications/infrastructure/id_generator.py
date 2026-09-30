"""Generador de ids de notifications (`IdGeneratorPort`)."""

import uuid


class UuidGenerator:
    """Ids `uuid4` para tokens de dispositivo."""

    def new_id(self) -> uuid.UUID:
        return uuid.uuid4()
