"""Tests unitarios de la huella de dedupe (spec 004 SS3, AC-5.1/AC-5.2/AC-5.3)."""

from dataclasses import replace
from datetime import UTC, datetime, timedelta, timezone
from decimal import Decimal
from uuid import uuid4

import pytest

from luka.modules.ledger.domain.dedupe import (
    BUCKET_SECONDS,
    SAME_CAPTURE_WINDOW,
    base_dedupe_key,
    candidate_keys,
    counterparty_dedupe_key,
    dedupe_key,
    is_compatible_capture,
    is_manual_key,
    is_same_capture,
    manual_dedupe_key,
    matches_tombstone,
    normalize_bank,
    same_counterparty,
    time_bucket,
)
from luka.modules.ledger.domain.entities import (
    Category,
    Transaction,
    TransactionTombstone,
    new_captured_transaction,
)
from luka.modules.ledger.domain.enums import Bank, Channel, Direction, FiscalTag

USER_ID = uuid4()
OCCURRED_AT = datetime(2026, 8, 5, 14, 30, 0, tzinfo=UTC)


def _key(**overrides: object) -> str:
    params: dict[str, object] = {
        "user_id": USER_ID,
        "bank": Bank.BANCOLOMBIA,
        "amount": Decimal("45900.00"),
        "direction": Direction.DEBIT,
        "bucket": time_bucket(OCCURRED_AT),
        "last4": "1234",
    }
    params.update(overrides)
    return dedupe_key(**params)  # type: ignore[arg-type]


@pytest.mark.unit
class TestDedupeKey:
    def test_mismo_input_misma_clave(self) -> None:
        assert _key() == _key()

    def test_cambiar_user_id_cambia_clave(self) -> None:
        assert _key() != _key(user_id=uuid4())

    def test_cambiar_bank_cambia_clave(self) -> None:
        assert _key() != _key(bank=Bank.NEQUI)

    def test_cambiar_amount_cambia_clave(self) -> None:
        assert _key() != _key(amount=Decimal("45901.00"))

    def test_cambiar_direction_cambia_clave(self) -> None:
        assert _key() != _key(direction=Direction.CREDIT)

    def test_cambiar_bucket_cambia_clave(self) -> None:
        assert _key() != _key(bucket=time_bucket(OCCURRED_AT) + 1)

    def test_cambiar_last4_cambia_clave(self) -> None:
        assert _key() != _key(last4="9999")

    def test_last4_none_equivale_a_guiones(self) -> None:
        assert _key(last4=None) == _key(last4="----")

    def test_decimal_45900_y_45900_00_dan_la_misma_clave(self) -> None:
        assert _key(amount=Decimal("45900")) == _key(amount=Decimal("45900.00"))

    def test_offset_menos_5_y_utc_equivalente_dan_la_misma_clave(self) -> None:
        bogota_tz = timezone(timedelta(hours=-5))
        utc_instant = datetime(2026, 8, 5, 19, 30, 0, tzinfo=UTC)
        bogota_instant = utc_instant.astimezone(bogota_tz)
        assert utc_instant == bogota_instant  # mismo instante, offset distinto
        assert time_bucket(utc_instant) == time_bucket(bogota_instant)
        assert _key(bucket=time_bucket(utc_instant)) == _key(bucket=time_bucket(bogota_instant))

    def test_naive_datetime_en_time_bucket_lanza_value_error(self) -> None:
        with pytest.raises(ValueError, match="tz-aware"):
            time_bucket(datetime(2026, 8, 5, 14, 30, 0))


@pytest.mark.unit
class TestCandidateKeys:
    def test_devuelve_tres_claves_con_el_indice_1_canonico(self) -> None:
        bucket = time_bucket(OCCURRED_AT)
        keys = candidate_keys(
            user_id=USER_ID,
            bank=Bank.BANCOLOMBIA,
            amount=Decimal("45900.00"),
            direction=Direction.DEBIT,
            occurred_at=OCCURRED_AT,
            last4="1234",
        )
        assert keys[1] == _key(bucket=bucket)
        assert keys[0] == _key(bucket=bucket - 1)
        assert keys[2] == _key(bucket=bucket + 1)

    def test_14_29_59_y_14_30_00_en_buckets_distintos_pero_candidatos_mutuos(self) -> None:
        before = datetime(2026, 8, 5, 14, 29, 59, tzinfo=UTC)
        boundary = datetime(2026, 8, 5, 14, 30, 0, tzinfo=UTC)
        assert time_bucket(before) != time_bucket(boundary)

        common = {
            "user_id": USER_ID,
            "bank": Bank.BANCOLOMBIA,
            "amount": Decimal("45900.00"),
            "direction": Direction.DEBIT,
            "last4": "1234",
        }
        keys_before = candidate_keys(occurred_at=before, **common)  # type: ignore[arg-type]
        keys_boundary = candidate_keys(occurred_at=boundary, **common)  # type: ignore[arg-type]

        canonical_before = _key(bucket=time_bucket(before))
        canonical_boundary = _key(bucket=time_bucket(boundary))
        assert canonical_boundary in keys_before
        assert canonical_before in keys_boundary


@pytest.mark.unit
class TestIsSameCapture:
    def test_true_a_los_9_min_59_s(self) -> None:
        a = OCCURRED_AT
        b = OCCURRED_AT + timedelta(minutes=9, seconds=59)
        assert is_same_capture(a, b) is True

    def test_true_exactamente_en_el_borde_de_10_min(self) -> None:
        a = OCCURRED_AT
        b = OCCURRED_AT + SAME_CAPTURE_WINDOW
        assert is_same_capture(a, b) is True

    def test_false_a_los_10_min_1_s(self) -> None:
        a = OCCURRED_AT
        b = OCCURRED_AT + timedelta(minutes=10, seconds=1)
        assert is_same_capture(a, b) is False

    def test_naive_datetime_lanza_value_error(self) -> None:
        with pytest.raises(ValueError, match="tz-aware"):
            is_same_capture(OCCURRED_AT, datetime(2026, 8, 5, 14, 35, 0))


@pytest.mark.unit
class TestManualDedupeKey:
    def test_formato_manual_prefijo(self) -> None:
        assert manual_dedupe_key("a" * 16) == f"manual:{'a' * 16}"

    def test_nunca_tiene_forma_de_hash_sha256_de_64_hex(self) -> None:
        key = manual_dedupe_key("b" * 64)
        assert key != "b" * 64
        assert key.startswith("manual:")

    def test_hex_invalido_lanza_value_error(self) -> None:
        with pytest.raises(ValueError, match="random_hex"):
            manual_dedupe_key("no-es-hex")

    def test_hex_demasiado_corto_lanza_value_error(self) -> None:
        with pytest.raises(ValueError, match="random_hex"):
            manual_dedupe_key("abc123")


@pytest.mark.unit
class TestNormalizeBank:
    def test_bancolombia_con_espacios_y_mayusculas(self) -> None:
        assert normalize_bank("BANCOLOMBIA ") == "bancolombia"

    def test_banco_desconocido_devuelve_other(self) -> None:
        assert normalize_bank("un_banco_raro") == "other"

    def test_acepta_bank_enum_directamente(self) -> None:
        assert normalize_bank(Bank.NEQUI) == "nequi"


@pytest.mark.unit
def test_bucket_seconds_es_600() -> None:
    assert BUCKET_SECONDS == 600


@pytest.mark.unit
class TestSameCounterparty:
    """Dos capturas entre personas con contrapartes distintas nunca son el mismo
    movimiento (spec 004 SS3): tres amigos que envian $7.100 a la vez."""

    def test_mismo_nombre_es_la_misma_contraparte(self) -> None:
        assert same_counterparty("MANUEL NIETO", "Manuel Nieto")

    def test_tildes_y_puntuacion_no_importan(self) -> None:
        assert same_counterparty("TOMÁS RODRÍGUEZ", "tomas rodriguez.")

    def test_nombre_recortado_es_la_misma_contraparte(self) -> None:
        assert same_counterparty("MANUEL", "MANUEL NIETO")

    def test_nombres_distintos_no_son_la_misma_contraparte(self) -> None:
        assert not same_counterparty("MANUEL NIETO", "MARIANA GOMEZ ABRIL")

    def test_un_apellido_en_comun_no_alcanza(self) -> None:
        assert not same_counterparty("JUAN GOMEZ", "MARIANA GOMEZ ABRIL")

    def test_nombre_sin_letras_no_es_contraparte(self) -> None:
        assert not same_counterparty("123", "MANUEL NIETO")


@pytest.mark.unit
class TestCounterpartyKey:
    def test_es_determinista_e_ignora_tildes_y_mayusculas(self) -> None:
        base = _key()
        assert counterparty_dedupe_key(base, "Tomás Rodríguez") == counterparty_dedupe_key(
            base, "TOMAS RODRIGUEZ"
        )

    def test_distinta_de_la_clave_base_y_por_contraparte(self) -> None:
        base = _key()
        manuel = counterparty_dedupe_key(base, "MANUEL NIETO")
        mariana = counterparty_dedupe_key(base, "MARIANA GOMEZ ABRIL")
        assert manuel != mariana
        assert manuel.startswith(f"{base}:")
        assert base_dedupe_key(manuel) == base
        assert base_dedupe_key(base) == base


_CATEGORY = Category(
    id=uuid4(),
    user_id=None,
    slug="sin_categoria",
    name="Sin categoria",
    icon=None,
    color=None,
    fiscal_tag=FiscalTag.NO_DEDUCIBLE,
)


def _captured(*, bank: Bank, last4: str | None, key: str | None = None) -> Transaction:
    """Captura ya guardada, con la huella que le habria calculado el caso de uso."""
    amount = Decimal("99000.00")
    return new_captured_transaction(
        id=uuid4(),
        user_id=USER_ID,
        amount=amount,
        direction=Direction.DEBIT,
        occurred_at=OCCURRED_AT,
        category=_CATEGORY,
        now=OCCURRED_AT,
        bank=bank,
        last4=last4,
        merchant="FRISBY",
        description=None,
        account_id=None,
        parsed_by="rule:test",
        confidence=None,
        dedupe_key=key
        or dedupe_key(
            user_id=USER_ID,
            bank=bank,
            amount=amount,
            direction=Direction.DEBIT,
            bucket=time_bucket(OCCURRED_AT),
            last4=last4,
        ),
    )


@pytest.mark.unit
class TestIsCompatibleCapture:
    """Fusion entre canales (spec 004 SS3): Apple Pay solo trae el nombre de la
    tarjeta, asi que puede llegar sin banco (`other`) o sin `last4` mientras el
    correo de la misma compra trae los dos."""

    def test_apple_pay_sin_banco_ni_last4_y_correo_completo(self) -> None:
        existing = _captured(bank=Bank.OTHER, last4=None)
        assert is_compatible_capture(existing, bank=Bank.BANCOLOMBIA, last4="1234")

    def test_correo_completo_y_apple_pay_sin_banco_ni_last4(self) -> None:
        existing = _captured(bank=Bank.BANCOLOMBIA, last4="1234")
        assert is_compatible_capture(existing, bank=Bank.OTHER, last4=None)

    def test_mismo_banco_y_una_sin_last4(self) -> None:
        existing = _captured(bank=Bank.BANCOLOMBIA, last4=None)
        assert is_compatible_capture(existing, bank=Bank.BANCOLOMBIA, last4="1234")

    def test_mismo_last4_con_banco_desconocido(self) -> None:
        existing = _captured(bank=Bank.OTHER, last4="1234")
        assert is_compatible_capture(existing, bank=Bank.BANCOLOMBIA, last4="1234")

    def test_last4_distintos_no_son_la_misma_compra(self) -> None:
        existing = _captured(bank=Bank.BANCOLOMBIA, last4="5678")
        assert not is_compatible_capture(existing, bank=Bank.BANCOLOMBIA, last4="1234")

    def test_bancos_conocidos_distintos_no_son_la_misma_compra(self) -> None:
        existing = _captured(bank=Bank.NEQUI, last4=None)
        assert not is_compatible_capture(existing, bank=Bank.BANCOLOMBIA, last4=None)

    def test_registro_manual_nunca_se_fusiona(self) -> None:
        existing = _captured(bank=Bank.OTHER, last4=None, key=manual_dedupe_key("ab" * 8))
        assert not is_compatible_capture(existing, bank=Bank.BANCOLOMBIA, last4="1234")

    def test_transferencia_emparejada_nunca_se_fusiona(self) -> None:
        existing = replace(_captured(bank=Bank.OTHER, last4=None), transfer_pair_id=uuid4())
        assert not is_compatible_capture(existing, bank=Bank.BANCOLOMBIA, last4="1234")

    def test_huella_que_no_se_puede_recalcular_no_se_fusiona(self) -> None:
        """Si la hora se edito despues, la huella ya no dice que `last4` tenia:
        ante la duda no se fusiona (AC-5.3)."""
        existing = _captured(bank=Bank.OTHER, last4=None, key="f" * 64)
        assert not is_compatible_capture(existing, bank=Bank.BANCOLOMBIA, last4="1234")
        assert is_compatible_capture(existing, bank=Bank.BANCOLOMBIA, last4=None)


def _tombstone(
    *, bank: Bank, last4: str | None, channels: frozenset[Channel]
) -> TransactionTombstone:
    """Lapida de una captura borrada, con la huella que tenia."""
    tx = _captured(bank=bank, last4=last4)
    return TransactionTombstone(
        id=uuid4(),
        user_id=tx.user_id,
        dedupe_key=tx.dedupe_key,
        bank=bank,
        amount=tx.amount,
        direction=tx.direction,
        occurred_at=tx.occurred_at,
        channels=channels,
        deleted_at=OCCURRED_AT + timedelta(hours=1),
    )


def _keys(*, bank: Bank, last4: str | None, at: datetime = OCCURRED_AT) -> tuple[str, ...]:
    return candidate_keys(
        user_id=USER_ID,
        bank=bank,
        amount=Decimal("99000.00"),
        direction=Direction.DEBIT,
        occurred_at=at,
        last4=last4,
    )


@pytest.mark.unit
class TestMatchesTombstone:
    """Una compra borrada no vuelve con otra fuente (spec 004 SS3)."""

    def test_la_misma_huella_dentro_de_la_ventana(self) -> None:
        tombstone = _tombstone(
            bank=Bank.BANCOLOMBIA, last4="1234", channels=frozenset({Channel.EMAIL})
        )
        later = OCCURRED_AT + timedelta(minutes=3)
        assert matches_tombstone(
            tombstone,
            keys=_keys(bank=Bank.BANCOLOMBIA, last4="1234", at=later),
            bank=Bank.BANCOLOMBIA,
            last4="1234",
            occurred_at=later,
            channel=Channel.EMAIL,
        )

    def test_el_correo_tardio_de_un_atajo_borrado(self) -> None:
        tombstone = _tombstone(
            bank=Bank.OTHER, last4=None, channels=frozenset({Channel.NOTIFICATION})
        )
        assert matches_tombstone(
            tombstone,
            keys=_keys(bank=Bank.BANCOLOMBIA, last4="1234"),
            bank=Bank.BANCOLOMBIA,
            last4="1234",
            occurred_at=OCCURRED_AT,
            channel=Channel.EMAIL,
        )

    def test_otro_aviso_del_mismo_canal_es_otra_compra(self) -> None:
        tombstone = _tombstone(
            bank=Bank.OTHER, last4=None, channels=frozenset({Channel.NOTIFICATION})
        )
        assert not matches_tombstone(
            tombstone,
            keys=_keys(bank=Bank.BANCOLOMBIA, last4="1234"),
            bank=Bank.BANCOLOMBIA,
            last4="1234",
            occurred_at=OCCURRED_AT,
            channel=Channel.NOTIFICATION,
        )

    def test_fuera_de_la_ventana_no_coincide(self) -> None:
        tombstone = _tombstone(
            bank=Bank.BANCOLOMBIA, last4="1234", channels=frozenset({Channel.EMAIL})
        )
        later = OCCURRED_AT + timedelta(minutes=11)
        assert not matches_tombstone(
            tombstone,
            keys=_keys(bank=Bank.BANCOLOMBIA, last4="1234", at=later),
            bank=Bank.BANCOLOMBIA,
            last4="1234",
            occurred_at=later,
            channel=Channel.EMAIL,
        )

    def test_last4_distinto_no_coincide(self) -> None:
        tombstone = _tombstone(
            bank=Bank.BANCOLOMBIA, last4="5678", channels=frozenset({Channel.EMAIL})
        )
        assert not matches_tombstone(
            tombstone,
            keys=_keys(bank=Bank.BANCOLOMBIA, last4="1234"),
            bank=Bank.BANCOLOMBIA,
            last4="1234",
            occurred_at=OCCURRED_AT,
            channel=Channel.NOTIFICATION,
        )


def test_is_manual_key() -> None:
    assert is_manual_key(manual_dedupe_key("ab" * 8))
    assert not is_manual_key("a" * 64)
