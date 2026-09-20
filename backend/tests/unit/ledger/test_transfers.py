"""Tests unitarios del matcher de transferencias (spec 004 SS4, RF-6, AC-6.1/6.2/6.3)."""

from dataclasses import replace
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from finanzia.modules.ledger.domain.entities import Category, Transaction
from finanzia.modules.ledger.domain.enums import Bank, Direction, FiscalTag, Kind
from finanzia.modules.ledger.domain.errors import TransferPairInvalid
from finanzia.modules.ledger.domain.transfers import (
    TRANSFER_WINDOW,
    Ambiguous,
    Matched,
    NoMatch,
    find_transfer_match,
    is_transfer_candidate,
    pair,
    unpair,
)

USER_ID = uuid4()
OTHER_USER_ID = uuid4()
NOW = datetime(2026, 8, 5, 15, 0, 0, tzinfo=UTC)
OCCURRED_AT = datetime(2026, 8, 5, 14, 30, 0, tzinfo=UTC)

CATEGORY_GENERIC = Category(
    id=uuid4(),
    user_id=None,
    slug="sin_categoria",
    name="Sin categoría",
    icon=None,
    color=None,
    fiscal_tag=FiscalTag.NO_DEDUCIBLE,
)
CATEGORY_TRANSFER = Category(
    id=uuid4(),
    user_id=None,
    slug="transferencias",
    name="Transferencias",
    icon=None,
    color=None,
    fiscal_tag=FiscalTag.TRANSFERENCIA,
)


def _tx(  # noqa: PLR0913 - helper de fixtures, uno por atributo relevante de Transaction
    *,
    direction: Direction = Direction.DEBIT,
    amount: Decimal = Decimal("100000.00"),
    occurred_at: datetime = OCCURRED_AT,
    account_id: UUID | None = None,
    user_id: UUID = USER_ID,
    bank: Bank = Bank.BANCOLOMBIA,
    kind: Kind | None = None,
    transfer_pair_id: UUID | None = None,
    transfer_exclusions: frozenset[UUID] = frozenset(),
) -> Transaction:
    resolved_kind = kind or (Kind.EXPENSE if direction == Direction.DEBIT else Kind.INCOME)
    return Transaction(
        id=uuid4(),
        user_id=user_id,
        amount=amount,
        currency="COP",
        direction=direction,
        kind=resolved_kind,
        occurred_at=occurred_at,
        merchant=None,
        description=None,
        bank=bank,
        account_id=account_id if account_id is not None else uuid4(),
        category_id=CATEGORY_GENERIC.id,
        fiscal_tag=(
            FiscalTag.TRANSFERENCIA if resolved_kind == Kind.TRANSFER else FiscalTag.NO_DEDUCIBLE
        ),
        transfer_pair_id=transfer_pair_id,
        transfer_auto=False,
        transfer_exclusions=transfer_exclusions,
        dedupe_key=uuid4().hex,
        parsed_by="test",
        confidence=None,
        notes=None,
        created_at=NOW,
        updated_at=NOW,
    )


@pytest.mark.unit
class TestIsTransferCandidate:
    def test_debito_bancolombia_y_credito_nequi_mismo_monto_dentro_de_48h(self) -> None:
        debit = _tx(direction=Direction.DEBIT, bank=Bank.BANCOLOMBIA)
        credit = _tx(
            direction=Direction.CREDIT,
            bank=Bank.NEQUI,
            occurred_at=OCCURRED_AT + timedelta(hours=1),
        )
        assert is_transfer_candidate(debit, credit) is True
        assert is_transfer_candidate(credit, debit) is True

    def test_misma_cuenta_no_es_candidato(self) -> None:
        account_id = uuid4()
        a = _tx(direction=Direction.DEBIT, account_id=account_id)
        b = _tx(direction=Direction.CREDIT, account_id=account_id)
        assert is_transfer_candidate(a, b) is False

    def test_una_cuenta_none_no_es_candidato(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        b = replace(_tx(direction=Direction.CREDIT), account_id=None)
        assert is_transfer_candidate(a, b) is False

    def test_48h_mas_1_segundo_no_es_candidato(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        just_over = OCCURRED_AT + TRANSFER_WINDOW + timedelta(seconds=1)
        b = _tx(direction=Direction.CREDIT, occurred_at=just_over)
        assert is_transfer_candidate(a, b) is False

    def test_exactamente_48h_es_candidato(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        b = _tx(direction=Direction.CREDIT, occurred_at=OCCURRED_AT + TRANSFER_WINDOW)
        assert is_transfer_candidate(a, b) is True

    def test_ya_emparejada_no_es_candidato(self) -> None:
        a = _tx(direction=Direction.DEBIT, transfer_pair_id=uuid4())
        b = _tx(direction=Direction.CREDIT)
        assert is_transfer_candidate(a, b) is False

    def test_excluida_no_es_candidato(self) -> None:
        b = _tx(direction=Direction.CREDIT)
        a = _tx(direction=Direction.DEBIT, transfer_exclusions=frozenset({b.id}))
        assert is_transfer_candidate(a, b) is False

    def test_distinto_usuario_no_es_candidato(self) -> None:
        a = _tx(direction=Direction.DEBIT, user_id=USER_ID)
        b = _tx(direction=Direction.CREDIT, user_id=OTHER_USER_ID)
        assert is_transfer_candidate(a, b) is False

    def test_mismo_id_no_es_candidato(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        assert is_transfer_candidate(a, a) is False

    def test_monto_distinto_no_es_candidato(self) -> None:
        a = _tx(direction=Direction.DEBIT, amount=Decimal("100000.00"))
        b = _tx(direction=Direction.CREDIT, amount=Decimal("100001.00"))
        assert is_transfer_candidate(a, b) is False

    def test_misma_direccion_no_es_candidato(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        b = _tx(direction=Direction.DEBIT)
        assert is_transfer_candidate(a, b) is False

    def test_ya_marcada_como_transfer_no_es_candidato(self) -> None:
        a = _tx(direction=Direction.DEBIT, kind=Kind.TRANSFER)
        b = _tx(direction=Direction.CREDIT)
        assert is_transfer_candidate(a, b) is False


@pytest.mark.unit
class TestFindTransferMatch:
    def test_sin_candidatos_es_nomatch(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        assert find_transfer_match(a, []) == NoMatch()

    def test_un_candidato_es_matched(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        b = _tx(direction=Direction.CREDIT)
        result = find_transfer_match(a, [b])
        assert isinstance(result, Matched)
        assert result.other_id == b.id

    def test_dos_candidatos_es_ambiguous_con_ids_ordenados(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        b = _tx(direction=Direction.CREDIT)
        c = _tx(direction=Direction.CREDIT)
        result = find_transfer_match(a, [b, c])
        assert isinstance(result, Ambiguous)
        assert result.candidate_ids == tuple(sorted([b.id, c.id]))


@pytest.mark.unit
class TestPair:
    def test_cruza_ids_y_marca_kind_fiscal_tag_auto(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        b = _tx(direction=Direction.CREDIT)
        paired_a, paired_b = pair(a, b, auto=True, now=NOW)
        assert paired_a.kind == Kind.TRANSFER
        assert paired_b.kind == Kind.TRANSFER
        assert paired_a.fiscal_tag == FiscalTag.TRANSFERENCIA
        assert paired_b.fiscal_tag == FiscalTag.TRANSFERENCIA
        assert paired_a.transfer_pair_id == b.id
        assert paired_b.transfer_pair_id == a.id
        assert paired_a.transfer_auto is True
        assert paired_b.transfer_auto is True
        assert paired_a.updated_at == NOW
        assert paired_b.updated_at == NOW

    def test_misma_direccion_lanza_transfer_pair_invalid(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        b = _tx(direction=Direction.DEBIT)
        with pytest.raises(TransferPairInvalid):
            pair(a, b, auto=False, now=NOW)

    def test_distinto_usuario_lanza_transfer_pair_invalid(self) -> None:
        a = _tx(direction=Direction.DEBIT, user_id=USER_ID)
        b = _tx(direction=Direction.CREDIT, user_id=OTHER_USER_ID)
        with pytest.raises(TransferPairInvalid):
            pair(a, b, auto=False, now=NOW)

    def test_ya_emparejada_lanza_transfer_pair_invalid(self) -> None:
        a = _tx(direction=Direction.DEBIT, transfer_pair_id=uuid4())
        b = _tx(direction=Direction.CREDIT)
        with pytest.raises(TransferPairInvalid):
            pair(a, b, auto=False, now=NOW)


@pytest.mark.unit
class TestUnpair:
    def test_restaura_kind_fiscal_tag_limpia_par_y_agrega_exclusion_mutua(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        b = _tx(direction=Direction.CREDIT)
        paired_a, paired_b = pair(a, b, auto=True, now=NOW)

        later = NOW + timedelta(minutes=5)
        unpaired_a, unpaired_b = unpair(
            paired_a,
            paired_b,
            category_tags=(FiscalTag.NO_DEDUCIBLE, FiscalTag.INGRESO_NO_LABORAL),
            now=later,
        )

        assert unpaired_a.kind == Kind.EXPENSE
        assert unpaired_b.kind == Kind.INCOME
        assert unpaired_a.fiscal_tag == FiscalTag.NO_DEDUCIBLE
        assert unpaired_b.fiscal_tag == FiscalTag.INGRESO_NO_LABORAL
        assert unpaired_a.transfer_pair_id is None
        assert unpaired_b.transfer_pair_id is None
        assert unpaired_a.transfer_auto is False
        assert unpaired_b.transfer_auto is False
        assert b.id in unpaired_a.transfer_exclusions
        assert a.id in unpaired_b.transfer_exclusions
        assert unpaired_a.updated_at == later

    def test_tras_desmarcar_find_transfer_match_devuelve_nomatch(self) -> None:
        a = _tx(direction=Direction.DEBIT)
        b = _tx(direction=Direction.CREDIT)
        paired_a, paired_b = pair(a, b, auto=True, now=NOW)
        unpaired_a, unpaired_b = unpair(
            paired_a,
            paired_b,
            category_tags=(FiscalTag.NO_DEDUCIBLE, FiscalTag.INGRESO_NO_LABORAL),
            now=NOW,
        )
        assert find_transfer_match(unpaired_a, [unpaired_b]) == NoMatch()
