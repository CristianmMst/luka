"""Tests unitarios de entidades y factories de ledger (spec 004 SS2, SS4)."""

from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4

import pytest

from finanzia.modules.ledger.domain.entities import (
    Category,
    LinkedAccount,
    TransactionSource,
    new_captured_transaction,
    new_manual_transaction,
    quantize_amount,
)
from finanzia.modules.ledger.domain.enums import (
    AccountKind,
    Bank,
    Channel,
    Direction,
    FiscalTag,
    Kind,
)
from finanzia.modules.ledger.domain.errors import InvalidAmount, InvalidLast4

NOW = datetime(2026, 8, 5, 15, 0, 0, tzinfo=UTC)
OCCURRED_AT = datetime(2026, 8, 5, 14, 30, 0, tzinfo=UTC)

CATEGORY_GENERIC = Category(
    id=uuid4(),
    user_id=None,
    slug="mercado",
    name="Mercado",
    icon=None,
    color=None,
    fiscal_tag=FiscalTag.NO_DEDUCIBLE,
)
CATEGORY_TRANSFERENCIAS = Category(
    id=uuid4(),
    user_id=None,
    slug="transferencias",
    name="Transferencias",
    icon=None,
    color=None,
    fiscal_tag=FiscalTag.TRANSFERENCIA,
)
CATEGORY_USER = Category(
    id=uuid4(),
    user_id=uuid4(),
    slug=None,
    name="Mi categoria",
    icon=None,
    color=None,
    fiscal_tag=FiscalTag.INGRESO_NO_LABORAL,
)


@pytest.mark.unit
class TestQuantizeAmount:
    def test_redondea_half_up_a_2_decimales(self) -> None:
        assert quantize_amount("45900.005") == Decimal("45900.01")

    def test_acepta_decimal_int_y_str(self) -> None:
        assert quantize_amount(Decimal("100")) == Decimal("100.00")
        assert quantize_amount(100) == Decimal("100.00")
        assert quantize_amount("100.1") == Decimal("100.10")

    def test_cero_lanza_invalid_amount(self) -> None:
        with pytest.raises(InvalidAmount):
            quantize_amount(Decimal("0"))

    def test_negativo_lanza_invalid_amount(self) -> None:
        with pytest.raises(InvalidAmount):
            quantize_amount(Decimal("-1"))

    def test_no_finito_lanza_invalid_amount(self) -> None:
        with pytest.raises(InvalidAmount):
            quantize_amount(Decimal("NaN"))

    def test_string_invalido_lanza_invalid_amount(self) -> None:
        with pytest.raises(InvalidAmount):
            quantize_amount("no-es-un-numero")


@pytest.mark.unit
class TestTransactionSource:
    def test_construye_con_datetime_tz_aware(self) -> None:
        source = TransactionSource(
            id=uuid4(),
            transaction_id=uuid4(),
            raw_message_id=uuid4(),
            channel=Channel.EMAIL,
            received_at=OCCURRED_AT,
        )
        assert source.channel == Channel.EMAIL

    def test_received_at_naive_lanza_value_error(self) -> None:
        with pytest.raises(ValueError, match="tz-aware"):
            TransactionSource(
                id=uuid4(),
                transaction_id=uuid4(),
                raw_message_id=None,
                channel=Channel.MANUAL,
                received_at=datetime(2026, 8, 5, 14, 30, 0),
            )


@pytest.mark.unit
class TestTransactionRequiresAwareDatetimes:
    def test_occurred_at_naive_lanza_value_error_en_new_manual_transaction(self) -> None:
        with pytest.raises(ValueError, match="tz-aware"):
            new_manual_transaction(
                id=uuid4(),
                user_id=uuid4(),
                amount=Decimal("1000"),
                direction=Direction.DEBIT,
                occurred_at=datetime(2026, 8, 5, 14, 30, 0),
                category=CATEGORY_GENERIC,
                now=NOW,
                dedupe_key="manual:" + "d" * 16,
            )


@pytest.mark.unit
class TestLinkedAccount:
    def test_last4_valido(self) -> None:
        account = LinkedAccount(
            id=uuid4(),
            user_id=uuid4(),
            bank=Bank.BANCOLOMBIA,
            kind=AccountKind.SAVINGS,
            last4="1234",
            alias=None,
        )
        assert account.last4 == "1234"

    def test_last4_none_es_valido(self) -> None:
        account = LinkedAccount(
            id=uuid4(),
            user_id=uuid4(),
            bank=Bank.NEQUI,
            kind=AccountKind.WALLET,
            last4=None,
            alias="mi billetera",
        )
        assert account.last4 is None

    def test_last4_con_letras_lanza_invalid_last4(self) -> None:
        with pytest.raises(InvalidLast4):
            LinkedAccount(
                id=uuid4(),
                user_id=uuid4(),
                bank=Bank.BANCOLOMBIA,
                kind=AccountKind.SAVINGS,
                last4="12a4",
                alias=None,
            )

    def test_last4_con_5_digitos_lanza_invalid_last4(self) -> None:
        with pytest.raises(InvalidLast4):
            LinkedAccount(
                id=uuid4(),
                user_id=uuid4(),
                bank=Bank.BANCOLOMBIA,
                kind=AccountKind.SAVINGS,
                last4="12345",
                alias=None,
            )


@pytest.mark.unit
class TestCategoryIsSystem:
    def test_categoria_del_sistema(self) -> None:
        assert CATEGORY_GENERIC.is_system is True

    def test_categoria_de_usuario(self) -> None:
        assert CATEGORY_USER.is_system is False


@pytest.mark.unit
class TestNewManualTransaction:
    def test_invariantes_basicas(self) -> None:
        tx = new_manual_transaction(
            id=uuid4(),
            user_id=uuid4(),
            amount=Decimal("50000"),
            direction=Direction.DEBIT,
            occurred_at=OCCURRED_AT,
            category=CATEGORY_GENERIC,
            now=NOW,
            dedupe_key="manual:" + "a" * 16,
        )
        assert tx.kind == Kind.EXPENSE
        assert tx.fiscal_tag == FiscalTag.NO_DEDUCIBLE
        assert tx.category_id == CATEGORY_GENERIC.id
        assert tx.transfer_pair_id is None
        assert tx.transfer_auto is False
        assert tx.transfer_exclusions == frozenset()
        assert tx.currency == "COP"
        assert tx.created_at == NOW
        assert tx.updated_at == NOW
        assert tx.amount == Decimal("50000.00")
        assert tx.parsed_by == "manual"

    def test_kind_explicito_transfer_usa_fiscal_tag_transferencia(self) -> None:
        tx = new_manual_transaction(
            id=uuid4(),
            user_id=uuid4(),
            amount=Decimal("50000"),
            direction=Direction.DEBIT,
            occurred_at=OCCURRED_AT,
            category=CATEGORY_TRANSFERENCIAS,
            now=NOW,
            dedupe_key="manual:" + "b" * 16,
            kind=Kind.TRANSFER,
        )
        assert tx.kind == Kind.TRANSFER
        assert tx.fiscal_tag == FiscalTag.TRANSFERENCIA

    def test_direccion_credito_deriva_income(self) -> None:
        tx = new_manual_transaction(
            id=uuid4(),
            user_id=uuid4(),
            amount=Decimal("50000"),
            direction=Direction.CREDIT,
            occurred_at=OCCURRED_AT,
            category=CATEGORY_USER,
            now=NOW,
            dedupe_key="manual:" + "c" * 16,
        )
        assert tx.kind == Kind.INCOME
        assert tx.fiscal_tag == FiscalTag.INGRESO_NO_LABORAL


@pytest.mark.unit
class TestNewCapturedTransaction:
    def test_invariantes_basicas(self) -> None:
        tx = new_captured_transaction(
            id=uuid4(),
            user_id=uuid4(),
            amount=Decimal("45900"),
            direction=Direction.DEBIT,
            occurred_at=OCCURRED_AT,
            category=CATEGORY_GENERIC,
            now=NOW,
            bank=Bank.BANCOLOMBIA,
            last4="1234",
            merchant="RAPPI",
            description="Compra RAPPI",
            account_id=uuid4(),
            parsed_by="template:bancolombia_debito_v1",
            confidence=0.98,
            dedupe_key="a" * 64,
        )
        assert tx.kind == Kind.EXPENSE
        assert tx.fiscal_tag == FiscalTag.NO_DEDUCIBLE
        assert tx.transfer_pair_id is None
        assert tx.transfer_auto is False
        assert tx.transfer_exclusions == frozenset()
        assert tx.currency == "COP"
        assert tx.notes is None
        assert tx.parsed_by == "template:bancolombia_debito_v1"
        assert tx.confidence == 0.98
        assert tx.amount == Decimal("45900.00")
