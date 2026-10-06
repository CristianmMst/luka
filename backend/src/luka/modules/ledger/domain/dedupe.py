"""Huella de dedupe de transacciones capturadas (spec 004 SS3, AC-5.1/AC-5.2/AC-5.3)."""

import hashlib
import re
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import Protocol
from uuid import UUID

from luka.modules.ledger.domain.entities import (
    Transaction,
    TransactionTombstone,
    quantize_amount,
)
from luka.modules.ledger.domain.enums import Bank, Channel, Direction
from luka.modules.ledger.domain.self_transfer import normalize_person_name

BUCKET_SECONDS = 600
SAME_CAPTURE_WINDOW = timedelta(minutes=10)
# Igual que la ventana en la que una plantilla aun acepta un mensaje (spec 006 SS4.1):
# despues ya no llega otra fuente que la lapida tenga que frenar.
TOMBSTONE_RETENTION = timedelta(days=7)

_MANUAL_HEX = re.compile(r"^[0-9a-f]{16,64}$")
_MANUAL_PREFIX = "manual:"


def _require_aware(value: datetime) -> None:
    """Exige que `value` sea un datetime tz-aware (mismo contrato que `entities.py`)."""
    if value.tzinfo is None or value.tzinfo.utcoffset(value) is None:
        raise ValueError("datetime debe ser tz-aware")


def time_bucket(occurred_at: datetime) -> int:
    """Bucket de 10 minutos (floor, en UTC) del instante (spec 004 SS3)."""
    _require_aware(occurred_at)
    return int(occurred_at.astimezone(UTC).timestamp()) // BUCKET_SECONDS


def normalize_bank(bank: Bank | str) -> str:
    """Normaliza el banco a su valor canonico; desconocido -> `Bank.OTHER`."""
    try:
        return Bank(str(bank).strip().lower()).value
    except ValueError:
        return Bank.OTHER.value


def dedupe_key(  # noqa: PLR0913 - un parametro por componente de la formula (spec 004 SS3)
    *,
    user_id: UUID,
    bank: Bank | str,
    amount: Decimal,
    direction: Direction,
    bucket: int,
    last4: str | None,
) -> str:
    """Huella sha256 determinista de una transaccion capturada (spec 004 SS3)."""
    payload = (
        f"{user_id}|{normalize_bank(bank)}|{quantize_amount(amount):.2f}|"
        f"{direction.value}|{bucket}|{last4 or '----'}"
    )
    return hashlib.sha256(payload.encode()).hexdigest()


def candidate_keys(  # noqa: PLR0913 - un parametro por componente de la formula (spec 004 SS3)
    *,
    user_id: UUID,
    bank: Bank | str,
    amount: Decimal,
    direction: Direction,
    occurred_at: datetime,
    last4: str | None,
) -> tuple[str, str, str]:
    """Claves candidatas para los buckets N-1, N y N+1 (indice 1 = bucket canonico)."""
    bucket = time_bucket(occurred_at)

    def _key_for(candidate_bucket: int) -> str:
        return dedupe_key(
            user_id=user_id,
            bank=bank,
            amount=amount,
            direction=direction,
            bucket=candidate_bucket,
            last4=last4,
        )

    return (_key_for(bucket - 1), _key_for(bucket), _key_for(bucket + 1))


def is_manual_key(key: str) -> bool:
    """`True` si `key` es de un registro manual (`manual:<hex>`), nunca de una captura."""
    return key.startswith(_MANUAL_PREFIX)


def manual_dedupe_key(random_hex: str) -> str:
    """Clave de dedupe para registros manuales: `manual:<hex>` (nunca colisiona con SHA-256)."""
    normalized = random_hex.strip().lower()
    if not _MANUAL_HEX.match(normalized):
        raise ValueError(f"random_hex invalido (16-64 caracteres hex): {random_hex!r}")
    return f"{_MANUAL_PREFIX}{normalized}"


def is_same_capture(existing_occurred_at: datetime, incoming_occurred_at: datetime) -> bool:
    """`True` si ambos instantes caen dentro de la ventana de 10 min (AC-5.1/AC-5.3)."""
    _require_aware(existing_occurred_at)
    _require_aware(incoming_occurred_at)
    return abs(existing_occurred_at - incoming_occurred_at) <= SAME_CAPTURE_WINDOW


def same_counterparty(a: str, b: str) -> bool:
    """`True` si dos contrapartes de capturas entre personas son la misma persona.

    Los bancos recortan nombres distinto en correo y notificacion ("MARIANA GOMEZ"
    frente a "MARIANA GOMEZ ABRIL"): basta con que las palabras del mas corto esten
    todas en el mas largo (spec 004 SS3).
    """
    x = set(normalize_person_name(a))
    y = set(normalize_person_name(b))
    shorter, longer = (x, y) if len(x) <= len(y) else (y, x)
    return bool(shorter) and shorter <= longer


def counterparty_dedupe_key(base_key: str, counterparty: str) -> str:
    """Clave de una captura entre personas cuya clave base ya usa OTRA contraparte
    (mismo monto, cuenta y ventana: tres amigos que envian lo mismo a la vez):
    `<clave base>:<hash del nombre>`. El prefijo deja que la otra fuente del mismo
    envio la encuentre aunque traiga el nombre recortado (spec 004 SS3).
    """
    name = " ".join(normalize_person_name(counterparty))
    return f"{base_key}:{hashlib.sha256(name.encode()).hexdigest()[:16]}"


def base_dedupe_key(key: str) -> str:
    """La clave base de `key` (sin el sufijo de contraparte)."""
    return key.partition(":")[0]


def is_compatible_capture(existing: Transaction, *, bank: Bank | str, last4: str | None) -> bool:
    """`True` si una captura de otro canal puede ser la misma compra que `existing`
    aunque su huella no coincida (spec 004 SS3, fusion entre canales).

    Apple Pay solo trae el nombre de la tarjeta: puede llegar sin banco (`other`)
    o sin `last4` mientras el correo de la misma compra trae los dos. Los bancos
    deben ser iguales o uno `other`; los `last4`, iguales o uno ausente. El
    `last4` de `existing` no se guarda: se deduce recalculando su huella. Si no
    se puede (p. ej. se edito la hora), solo es compatible una entrante sin
    `last4`. Monto, direccion, ventana y canal los revisa el caso de uso.
    """
    if is_manual_key(existing.dedupe_key) or existing.transfer_pair_id is not None:
        return False
    return _footprint_compatible(existing, bank=bank, last4=last4)


class _Footprint(Protocol):
    """Lo que la huella de una captura deja ver: una transaccion viva o una lapida."""

    @property
    def user_id(self) -> UUID: ...
    @property
    def bank(self) -> Bank | None: ...
    @property
    def amount(self) -> Decimal: ...
    @property
    def direction(self) -> Direction: ...
    @property
    def occurred_at(self) -> datetime: ...
    @property
    def dedupe_key(self) -> str: ...


def _footprint_compatible(existing: _Footprint, *, bank: Bank | str, last4: str | None) -> bool:
    """Bancos iguales o uno `other`; `last4` iguales o uno ausente (spec 004 SS3)."""
    existing_bank = normalize_bank(existing.bank or Bank.OTHER)
    incoming_bank = normalize_bank(bank)
    if Bank.OTHER.value not in {existing_bank, incoming_bank} and existing_bank != incoming_bank:
        return False
    if last4 is None:
        return True

    bucket = time_bucket(existing.occurred_at)

    # Sin el sufijo de contraparte de una captura entre personas (`<base>:<hash>`).
    stored = base_dedupe_key(existing.dedupe_key)

    def stored_with(candidate: str | None) -> bool:
        return stored == dedupe_key(
            user_id=existing.user_id,
            bank=existing_bank,
            amount=existing.amount,
            direction=existing.direction,
            bucket=bucket,
            last4=candidate,
        )

    return stored_with(None) or stored_with(last4)


def matches_tombstone(  # noqa: PLR0913 - un parametro por dato de la captura entrante
    tombstone: TransactionTombstone,
    *,
    keys: tuple[str, ...],
    bank: Bank | str,
    last4: str | None,
    occurred_at: datetime,
    channel: Channel,
) -> bool:
    """`True` si la captura entrante es otra fuente de la compra que el usuario borro
    (spec 004 SS3): la misma huella dentro de la ventana, o una huella compatible de
    un canal que la compra borrada no tenia (la regla de fusion entre canales).
    Monto y direccion ya los filtro la consulta.
    """
    if not is_same_capture(tombstone.occurred_at, occurred_at):
        return False
    if base_dedupe_key(tombstone.dedupe_key) in keys:
        return True
    if channel in tombstone.channels:
        return False
    return _footprint_compatible(tombstone, bank=bank, last4=last4)
