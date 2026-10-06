"""Huella de dedupe de transacciones capturadas (spec 004 SS3, AC-5.1/AC-5.2/AC-5.3)."""

import hashlib
import re
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID

from luka.modules.ledger.domain.entities import quantize_amount
from luka.modules.ledger.domain.enums import Bank, Direction
from luka.modules.ledger.domain.self_transfer import normalize_person_name

BUCKET_SECONDS = 600
SAME_CAPTURE_WINDOW = timedelta(minutes=10)

_MANUAL_HEX = re.compile(r"^[0-9a-f]{16,64}$")


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


def manual_dedupe_key(random_hex: str) -> str:
    """Clave de dedupe para registros manuales: `manual:<hex>` (nunca colisiona con SHA-256)."""
    normalized = random_hex.strip().lower()
    if not _MANUAL_HEX.match(normalized):
        raise ValueError(f"random_hex invalido (16-64 caracteres hex): {random_hex!r}")
    return f"manual:{normalized}"


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
