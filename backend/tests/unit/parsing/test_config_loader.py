"""Tests unitarios del loader de config YAML de parsing (D6)."""

import pytest

from finanzia.modules.parsing.infrastructure.config_loader import ParsingConfig, load_parsing_config


@pytest.mark.unit
class TestLoadParsingConfig:
    def test_carga_y_cachea(self) -> None:
        config = load_parsing_config()
        assert isinstance(config, ParsingConfig)
        assert load_parsing_config() is config

    def test_templates_carga_bancolombia_con_4_plantillas(self) -> None:
        config = load_parsing_config()
        bank_config = config.templates.bank_config("bancolombia")
        assert bank_config is not None
        assert bank_config.version == 1
        assert len(bank_config.templates) == 4
        assert {t.id for t in bank_config.templates} == {
            "compra_tdeb",
            "transferencia_llave",
            "transferencia_llave_recibida",
            "nomina",
        }

    def test_senders_bancolombia_verificado(self) -> None:
        config = load_parsing_config()
        assert config.senders.known_banks() == {
            "bancolombia",
            "nequi",
            "davivienda",
            "daviplata",
            "bbva",
            "banco_bogota",
        }
        assert (
            config.senders.bank_for_email_sender(
                "alertasynotificaciones@an.notificacionesbancolombia.com"
            )
            == "bancolombia"
        )

    def test_capture_tiene_7_apps(self) -> None:
        config = load_parsing_config()
        assert len(config.capture.banking_apps) == 7
        assert config.capture.banking_apps["com.bancolombia.app"] == "bancolombia"
        assert config.capture.banking_apps["com.google.android.apps.walletnfcrel"] is None

    def test_capture_raw_es_el_dict_crudo_del_yaml(self) -> None:
        config = load_parsing_config()
        assert config.capture_raw["version"] == 1
        assert "banking_apps" in config.capture_raw
        assert "messages_apps" in config.capture_raw
