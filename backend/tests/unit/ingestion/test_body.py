"""Tests unitarios de `ingestion.domain.body` (spec 006 §2.3/§3.2/§4.4)."""

from datetime import UTC, datetime, timedelta
from typing import cast

import pytest

from luka.modules.ingestion.domain.body import (
    compose_body,
    purge_after_for,
    truncate_utf8,
    validate_external_id,
)
from luka.modules.ingestion.domain.enums import Channel
from luka.modules.ingestion.domain.errors import InvalidChannel, InvalidExternalId


@pytest.mark.unit
class TestComposeBody:
    def test_con_titulo_antepone_titulo_y_linea_en_blanco(self) -> None:
        assert compose_body("Alerta", "Compraste $100") == "Alerta\n\nCompraste $100"

    def test_sin_titulo_devuelve_solo_texto(self) -> None:
        assert compose_body(None, "Compraste $100") == "Compraste $100"

    def test_titulo_vacio_se_trata_como_ausente(self) -> None:
        assert compose_body("", "  hola  ") == "hola"

    def test_titulo_solo_espacios_se_trata_como_ausente(self) -> None:
        assert compose_body("   ", "hola") == "hola"

    def test_recorta_espacios_solo_en_los_extremos_del_resultado(self) -> None:
        # `strip()` opera sobre el resultado compuesto, no sobre `title`/`text` por
        # separado: solo desaparecen los espacios al inicio de `title` y al final de `text`.
        assert compose_body("  T  ", "  texto  ") == "T  \n\n  texto"


@pytest.mark.unit
class TestTruncateUtf8:
    def test_no_trunca_si_ya_cabe(self) -> None:
        assert truncate_utf8("hola", 100) == "hola"

    def test_trunca_sin_partir_caracter_multibyte(self) -> None:
        texto = "é" * 10000  # 'é' ocupa 2 bytes en UTF-8: 20000 bytes en total
        truncado = truncate_utf8(texto, 8192)

        encoded = truncado.encode("utf-8")
        assert len(encoded) <= 8192
        # Si se hubiera cortado a mitad de caracter, decode() lanzaria UnicodeDecodeError.
        assert encoded.decode("utf-8") == truncado
        assert truncado == "é" * (len(encoded) // 2)

    def test_no_excede_el_limite_de_bytes_con_ascii(self) -> None:
        texto = "x" * 20000
        truncado = truncate_utf8(texto, 8192)
        assert len(truncado.encode("utf-8")) <= 8192
        assert len(truncado) == 8192  # ascii: 1 char == 1 byte


@pytest.mark.unit
class TestPurgeAfterFor:
    def test_suma_los_dias_de_retencion(self) -> None:
        received = datetime(2026, 1, 1, tzinfo=UTC)
        assert purge_after_for(received, 90) == received + timedelta(days=90)


@pytest.mark.unit
class TestValidateExternalId:
    def test_notification_hex64_valido_no_lanza(self) -> None:
        validate_external_id(Channel.NOTIFICATION, "a" * 64)

    def test_sms_notification_hex64_valido_no_lanza(self) -> None:
        validate_external_id(Channel.SMS_NOTIFICATION, "0123456789abcdef" * 4)

    def test_notification_no_hex_lanza(self) -> None:
        with pytest.raises(InvalidExternalId):
            validate_external_id(Channel.NOTIFICATION, "not-a-hash")

    def test_notification_mayusculas_lanza(self) -> None:
        with pytest.raises(InvalidExternalId):
            validate_external_id(Channel.NOTIFICATION, "A" * 64)

    def test_notification_longitud_incorrecta_lanza(self) -> None:
        with pytest.raises(InvalidExternalId):
            validate_external_id(Channel.NOTIFICATION, "a" * 63)

    def test_email_no_vacio_valido_no_lanza(self) -> None:
        validate_external_id(Channel.EMAIL, "msg-123")

    def test_email_vacio_lanza(self) -> None:
        with pytest.raises(InvalidExternalId):
            validate_external_id(Channel.EMAIL, "")

    def test_email_demasiado_largo_lanza(self) -> None:
        with pytest.raises(InvalidExternalId):
            validate_external_id(Channel.EMAIL, "a" * 257)

    def test_email_con_espacio_lanza(self) -> None:
        with pytest.raises(InvalidExternalId):
            validate_external_id(Channel.EMAIL, "msg 123")

    def test_email_256_caracteres_es_valido(self) -> None:
        validate_external_id(Channel.EMAIL, "a" * 256)

    def test_canal_desconocido_lanza_invalid_channel(self) -> None:
        canal_invalido = cast("Channel", "whatsapp")
        with pytest.raises(InvalidChannel):
            validate_external_id(canal_invalido, "cualquiera")
