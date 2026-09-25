"""Guarda de paridad entre los enums de dominio, los `CHECK` de los ORM y las
migraciones (review final B-I2).

R4 prohibe que un modulo importe la lista de valores de otro, asi que la misma
lista cerrada vive hasta en 4 lugares: el enum de dominio (a veces uno por
modulo), la constante `_*_VALUES` del ORM y el literal de la migracion. Sin este
test, agregar un valor nuevo y olvidar el `CHECK` no se nota hasta que un
`IntegrityError` revienta dentro de un consumer (fila `pending` -> el cron la
republica cada 15 min para siempre).

Las migraciones se importan por ruta (`importlib`): no son un paquete, pero sus
modulos se cargan sin efectos secundarios (`op`/`sa` son imports perezosos).
Los tests no estan atados a los contratos de import-linter, asi que puede leer
los internals de todos los modulos a la vez.
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from types import ModuleType

import pytest

from finanzia.modules.ingestion.domain.enums import Channel as IngestionChannel
from finanzia.modules.ingestion.domain.enums import GmailConnectionStatus, RawMessageStatus
from finanzia.modules.ingestion.infrastructure import orm as ingestion_orm
from finanzia.modules.ledger.domain.enums import Bank
from finanzia.modules.ledger.domain.enums import Channel as LedgerChannel
from finanzia.modules.ledger.domain.review import ReviewReason, ReviewResolution
from finanzia.modules.ledger.infrastructure import orm as ledger_orm
from finanzia.modules.parsing.domain.enums import Channel as ParsingChannel
from finanzia.modules.parsing.domain.enums import ParseFailureReason

pytestmark = pytest.mark.unit

_MIGRATIONS_DIR = Path(__file__).resolve().parents[2] / "migrations" / "versions"


def _load_migration(filename: str) -> ModuleType:
    """Carga un modulo de migracion por ruta (las migraciones no son un paquete)."""
    name = f"_migration_{filename.removesuffix('.py')}"
    if name in sys.modules:
        return sys.modules[name]
    spec = importlib.util.spec_from_file_location(name, _MIGRATIONS_DIR / filename)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


_M0002 = _load_migration("0002_ledger_core.py")
_M0003 = _load_migration("0003_raw_messages_review.py")
_M0005 = _load_migration("0005_gmail_connections.py")
_M0007 = _load_migration("0007_review_resolution_reparsed.py")


def _values(sql_list: str) -> tuple[str, ...]:
    """`"'a','b'"` -> `("a", "b")` (el literal que va dentro de un `IN (...)`)."""
    return tuple(part.strip().strip("'") for part in sql_list.split(","))


def test_motivos_de_revision_coinciden_en_los_cuatro_lugares() -> None:
    esperado = tuple(r.value for r in ParseFailureReason)

    assert tuple(r.value for r in ReviewReason) == esperado
    assert _values(ledger_orm._REASON_VALUES) == esperado
    assert _values(_M0003._REASON_VALUES) == esperado


def test_resoluciones_de_revision_coinciden_con_orm_y_ultima_migracion() -> None:
    """0003 creo el `CHECK` con `converted`/`discarded`; 0007 lo reemplaza con
    `reparsed` agregado, y es la que manda en `head`.
    """
    esperado = tuple(r.value for r in ReviewResolution)

    assert _values(ledger_orm._RESOLUTION_VALUES) == esperado
    assert _values(_M0007._RESOLUTION_VALUES) == esperado
    assert _values(_M0007._PREVIOUS_RESOLUTION_VALUES) == _values(_M0003._RESOLUTION_VALUES)


def test_bancos_coinciden_en_enum_orm_y_migraciones() -> None:
    esperado = tuple(b.value for b in Bank)

    assert _values(ledger_orm._BANK_VALUES) == esperado
    assert _values(ingestion_orm._BANK_VALUES) == esperado
    assert _values(_M0002._BANK_VALUES) == esperado
    assert _values(_M0003._BANK_VALUES) == esperado


def test_canales_de_captura_coinciden_entre_ingestion_parsing_y_su_migracion() -> None:
    esperado = tuple(c.value for c in IngestionChannel)

    assert tuple(c.value for c in ParsingChannel) == esperado
    assert _values(ingestion_orm._CHANNEL_VALUES) == esperado
    assert _values(_M0003._CHANNEL_VALUES) == esperado


def test_canales_de_ledger_son_los_de_captura_mas_manual_y_nfc() -> None:
    """`ledger.Channel` es un superconjunto: agrega los origenes que no vienen de
    un `raw_message` (`manual`, `nfc`), asi que se compara aparte.
    """
    esperado = tuple(c.value for c in LedgerChannel)

    assert esperado == (*tuple(c.value for c in IngestionChannel), "manual", "nfc")
    assert _values(ledger_orm._CHANNEL_VALUES) == esperado
    assert _values(_M0002._CHANNEL_VALUES) == esperado


def test_estados_de_raw_message_coinciden_con_orm_y_migracion() -> None:
    esperado = tuple(s.value for s in RawMessageStatus)

    assert _values(ingestion_orm._STATUS_VALUES) == esperado
    assert _values(_M0003._STATUS_VALUES) == esperado


def test_estados_de_gmail_connection_coinciden_con_orm_y_migracion() -> None:
    esperado = tuple(s.value for s in GmailConnectionStatus)

    assert _values(ingestion_orm._GMAIL_CONNECTION_STATUS_VALUES) == esperado
    assert _values(_M0005._STATUS_VALUES) == esperado
