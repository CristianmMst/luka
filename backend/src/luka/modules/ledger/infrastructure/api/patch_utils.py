"""Ayudante compartido por los routers de PATCH: resuelve campos no-nulos.

Algunos campos de los DTO `*Patch` son `T | Unset` (sin rama `None`): la categoria,
el `kind` de una transaccion, el nombre/`fiscal_tag` de una categoria. Si el cliente
los envia explicitamente como `null`, no hay un valor `Unset` valido que representarlo:
se traduce a 400 `validation_error` en vez de dejar que `None` llegue al caso de uso.
"""

from luka.modules.ledger.application.dto import UNSET, Unset
from luka.shared.errors import ValidationAppError


def resolve_required_patch_field[T](value: T | None, *, present: bool, field: str) -> T | Unset:
    """`UNSET` si el campo no se envio; el valor si se envio; 400 si se envio `null`."""
    if not present:
        return UNSET
    if value is None:
        raise ValidationAppError(message=f"{field} no puede ser null", field=field)
    return value
