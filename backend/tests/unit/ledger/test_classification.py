"""Tests unitarios de clasificacion: kind, fiscal_tag y marcado de transferencias."""

from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4

import pytest

from luka.modules.ledger.domain.classification import (
    derive_kind,
    mark_as_transfer,
    resolve_fiscal_tag,
    unmark_transfer,
)
from luka.modules.ledger.domain.entities import Transaction
from luka.modules.ledger.domain.enums import Direction, FiscalTag, Kind

NOW = datetime(2026, 8, 5, 15, 0, 0, tzinfo=UTC)
OCCURRED_AT = datetime(2026, 8, 5, 14, 30, 0, tzinfo=UTC)


def _tx(*, direction: Direction, kind: Kind, fiscal_tag: FiscalTag) -> Transaction:
    return Transaction(
        id=uuid4(),
        user_id=uuid4(),
        amount=Decimal("50000.00"),
        currency="COP",
        direction=direction,
        kind=kind,
        occurred_at=OCCURRED_AT,
        merchant=None,
        description=None,
        bank=None,
        account_id=uuid4(),
        category_id=uuid4(),
        fiscal_tag=fiscal_tag,
        transfer_pair_id=None,
        transfer_auto=False,
        transfer_exclusions=frozenset(),
        dedupe_key=uuid4().hex,
        parsed_by="test",
        confidence=None,
        notes=None,
        created_at=NOW,
        updated_at=NOW,
    )


@pytest.mark.unit
class TestDeriveKind:
    @pytest.mark.parametrize(
        ("direction", "expected"),
        [(Direction.DEBIT, Kind.EXPENSE), (Direction.CREDIT, Kind.INCOME)],
    )
    def test_tabla_direccion_a_kind(self, direction: Direction, expected: Kind) -> None:
        assert derive_kind(direction) is expected


@pytest.mark.unit
class TestResolveFiscalTag:
    def test_transfer_siempre_es_transferencia(self) -> None:
        assert resolve_fiscal_tag(Kind.TRANSFER, FiscalTag.NO_DEDUCIBLE) == FiscalTag.TRANSFERENCIA

    def test_no_transfer_usa_la_etiqueta_de_la_categoria(self) -> None:
        salud = FiscalTag.DEDUCIBLE_SALUD
        laboral = FiscalTag.INGRESO_LABORAL
        assert resolve_fiscal_tag(Kind.EXPENSE, salud) == salud
        assert resolve_fiscal_tag(Kind.INCOME, laboral) == laboral


@pytest.mark.unit
class TestMarkUnmarkRoundTrip:
    def test_mark_as_transfer_fija_kind_y_fiscal_tag(self) -> None:
        tx = _tx(direction=Direction.DEBIT, kind=Kind.EXPENSE, fiscal_tag=FiscalTag.NO_DEDUCIBLE)
        later = NOW
        marked = mark_as_transfer(tx, now=later)
        assert marked.kind == Kind.TRANSFER
        assert marked.fiscal_tag == FiscalTag.TRANSFERENCIA
        assert marked.updated_at == later

    def test_unmark_transfer_restaura_kind_y_fiscal_tag_original(self) -> None:
        tx = _tx(direction=Direction.CREDIT, kind=Kind.EXPENSE, fiscal_tag=FiscalTag.NO_DEDUCIBLE)
        marked = mark_as_transfer(tx, now=NOW)
        unmarked = unmark_transfer(marked, category_fiscal_tag=FiscalTag.INGRESO_LABORAL, now=NOW)
        assert unmarked.kind == Kind.INCOME  # derivado de CREDIT, no del kind previo a marcar
        assert unmarked.fiscal_tag == FiscalTag.INGRESO_LABORAL
        assert unmarked.transfer_pair_id is None
        assert unmarked.transfer_auto is False

    def test_round_trip_mark_unmark_es_consistente(self) -> None:
        tx = _tx(direction=Direction.DEBIT, kind=Kind.EXPENSE, fiscal_tag=FiscalTag.DEDUCIBLE_SALUD)
        marked = mark_as_transfer(tx, now=NOW)
        unmarked = unmark_transfer(marked, category_fiscal_tag=tx.fiscal_tag, now=NOW)
        assert unmarked.kind == tx.kind
        assert unmarked.fiscal_tag == tx.fiscal_tag
