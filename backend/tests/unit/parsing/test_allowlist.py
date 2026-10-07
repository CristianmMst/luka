"""Tests unitarios de allowlists de captura (spec 006 §2.2/§3.1, AC-2.4/AC-3.3)."""

import pytest

from luka.modules.parsing.domain.allowlist import CaptureConfig, SenderAllowlist
from luka.modules.parsing.domain.errors import TemplateConfigError

SENDERS_CONFIG = {
    "version": 1,
    "banks": {
        "bancolombia": {
            "verified": True,
            "senders": [
                "alertasynotificaciones@an.notificacionesbancolombia.com",
                "@notificacionesbancolombia.com",
                "@bancolombia.com.co",
            ],
        },
        "nequi": {"verified": False, "senders": ["@nequi.com.co"]},
        "davivienda": {"verified": False, "senders": ["@davivienda.com"]},
        "daviplata": {"verified": False, "senders": ["@daviplata.com"]},
        "bbva": {"verified": False, "senders": ["@bbva.com.co"]},
        "banco_bogota": {"verified": False, "senders": ["@bancodebogota.com.co"]},
    },
}

CAPTURE_CONFIG = {
    "version": 1,
    "banking_apps": [
        {"package": "com.bancolombia.app", "bank": "bancolombia"},
        {"package": "com.nequi.MobileApp", "bank": "nequi"},
        {"package": "com.google.android.apps.walletnfcrel", "bank": None},
        {"package": "com.samsung.android.spay", "bank": None},
        {"package": "com.apple.wallet", "bank": None, "bank_from_title": True},
    ],
    "messages_apps": [
        "com.google.android.apps.messaging",
        "com.samsung.android.messaging",
    ],
    "sms_sender_patterns": [
        {"pattern": "(?i)bancolombia", "bank": "bancolombia"},
        {"pattern": "(?i)nequi", "bank": "nequi"},
    ],
}


@pytest.fixture
def allowlist() -> SenderAllowlist:
    return SenderAllowlist.from_config(SENDERS_CONFIG)


@pytest.fixture
def capture() -> CaptureConfig:
    return CaptureConfig.from_config(CAPTURE_CONFIG)


@pytest.mark.unit
class TestSenderAllowlist:
    def test_remitente_real_bancolombia(self, allowlist: SenderAllowlist) -> None:
        assert (
            allowlist.bank_for_email_sender(
                "alertasynotificaciones@an.notificacionesbancolombia.com"
            )
            == "bancolombia"
        )

    def test_remitente_con_display_name(self, allowlist: SenderAllowlist) -> None:
        sender = "Alertas <alertasynotificaciones@an.notificacionesbancolombia.com>"
        assert allowlist.bank_for_email_sender(sender) == "bancolombia"

    def test_remitente_no_soportado(self, allowlist: SenderAllowlist) -> None:
        assert allowlist.bank_for_email_sender("nu@nu.com.co") is None

    def test_dominio_hijo_de_phishing_no_matchea(self, allowlist: SenderAllowlist) -> None:
        assert allowlist.bank_for_email_sender("phish@bancolombia.com.co.evil.com") is None

    def test_subdominio_valido_matchea(self, allowlist: SenderAllowlist) -> None:
        assert allowlist.bank_for_email_sender("x@sub.bancolombia.com.co") == "bancolombia"

    def test_matching_case_insensitive(self, allowlist: SenderAllowlist) -> None:
        sender = "ALERTASYNOTIFICACIONES@AN.NOTIFICACIONESBANCOLOMBIA.COM"
        assert allowlist.bank_for_email_sender(sender) == "bancolombia"

    def test_display_name_nunca_se_matchea(self, allowlist: SenderAllowlist) -> None:
        sender = "DAVIVIENDA <nu@nu.com.co>"
        assert allowlist.bank_for_email_sender(sender) is None

    def test_known_banks_tiene_6(self, allowlist: SenderAllowlist) -> None:
        assert len(allowlist.known_banks()) == 6
        assert "bancolombia" in allowlist.known_banks()

    def test_config_invalida_lanza_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            SenderAllowlist.from_config({"banks": "no-es-un-mapeo"})

    def test_banco_sin_senders_lanza_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            SenderAllowlist.from_config({"banks": {"bancolombia": {"verified": True}}})

    def test_senders_no_es_lista_de_strings_lanza_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            SenderAllowlist.from_config({"banks": {"bancolombia": {"senders": [1, 2]}}})

    def test_sender_sin_arroba_no_matchea(self, allowlist: SenderAllowlist) -> None:
        assert allowlist.bank_for_email_sender("no-es-un-correo") is None


@pytest.mark.unit
class TestCaptureConfigNotification:
    def test_app_bancaria_aceptada_con_banco(self, capture: CaptureConfig) -> None:
        decision = capture.bank_for_notification("com.bancolombia.app", "notification", None)
        assert decision.accepted is True
        assert decision.bank == "bancolombia"

    def test_google_wallet_aceptada_sin_banco(self, capture: CaptureConfig) -> None:
        decision = capture.bank_for_notification(
            "com.google.android.apps.walletnfcrel", "notification", None
        )
        assert decision.accepted is True
        assert decision.bank is None

    def test_samsung_wallet_aceptada_sin_banco(self, capture: CaptureConfig) -> None:
        decision = capture.bank_for_notification("com.samsung.android.spay", "notification", None)
        assert decision.accepted is True
        assert decision.bank is None

    def test_apple_wallet_toma_el_banco_del_nombre_de_la_tarjeta(
        self, capture: CaptureConfig
    ) -> None:
        decision = capture.bank_for_notification(
            "com.apple.wallet", "notification", "Mastercard Bancolombia 1234"
        )
        assert decision.accepted is True
        assert decision.bank == "bancolombia"

    def test_apple_wallet_con_tarjeta_sin_banco_conocido(self, capture: CaptureConfig) -> None:
        for title in ("Visa Oro", None):
            decision = capture.bank_for_notification("com.apple.wallet", "notification", title)
            assert decision.accepted is True
            assert decision.bank is None

    def test_google_wallet_no_mira_el_titulo(self, capture: CaptureConfig) -> None:
        decision = capture.bank_for_notification(
            "com.google.android.apps.walletnfcrel", "notification", "Pago en Nequi Store"
        )
        assert decision.bank is None

    def test_bank_from_title_invalido_falla(self) -> None:
        config = {
            **CAPTURE_CONFIG,
            "banking_apps": [
                {"package": "com.apple.wallet", "bank": None, "bank_from_title": "si"}
            ],
        }
        with pytest.raises(TemplateConfigError):
            CaptureConfig.from_config(config)

    def test_app_no_soportada_rechazada(self, capture: CaptureConfig) -> None:
        decision = capture.bank_for_notification("com.whatsapp", "notification", None)
        assert decision.accepted is False
        assert decision.bank is None


@pytest.mark.unit
class TestCaptureConfigSms:
    def test_sms_titulo_bancolombia_aceptado(self, capture: CaptureConfig) -> None:
        decision = capture.bank_for_notification(
            "com.google.android.apps.messaging", "sms_notification", "Bancolombia"
        )
        assert decision.accepted is True
        assert decision.bank == "bancolombia"

    def test_sms_titulo_no_bancario_rechazado(self, capture: CaptureConfig) -> None:
        decision = capture.bank_for_notification(
            "com.google.android.apps.messaging", "sms_notification", "Mama"
        )
        assert decision.accepted is False
        assert decision.bank is None

    def test_sms_de_app_no_soportada_rechazado(self, capture: CaptureConfig) -> None:
        decision = capture.bank_for_notification("com.whatsapp", "sms_notification", "Bancolombia")
        assert decision.accepted is False

    def test_canal_desconocido_rechazado(self, capture: CaptureConfig) -> None:
        decision = capture.bank_for_notification("com.bancolombia.app", "email", None)
        assert decision.accepted is False

    def test_config_invalida_lanza_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            CaptureConfig.from_config({"banking_apps": []})

    def test_messages_apps_no_es_lista_lanza_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            CaptureConfig.from_config(
                {
                    "banking_apps": [{"package": "com.bancolombia.app", "bank": "bancolombia"}],
                    "messages_apps": "no-es-lista",
                    "sms_sender_patterns": [],
                }
            )

    def test_sms_sender_patterns_no_es_lista_lanza_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            CaptureConfig.from_config(
                {
                    "banking_apps": [{"package": "com.bancolombia.app", "bank": "bancolombia"}],
                    "messages_apps": [],
                    "sms_sender_patterns": "no-es-lista",
                }
            )

    def test_banking_app_sin_package_lanza_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            CaptureConfig.from_config(
                {
                    "banking_apps": [{"bank": "bancolombia"}],
                    "messages_apps": [],
                    "sms_sender_patterns": [],
                }
            )

    def test_sms_pattern_sin_bank_lanza_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            CaptureConfig.from_config(
                {
                    "banking_apps": [{"package": "com.bancolombia.app", "bank": "bancolombia"}],
                    "messages_apps": [],
                    "sms_sender_patterns": [{"pattern": "(?i)bancolombia"}],
                }
            )

    def test_sms_pattern_regex_invalida_lanza_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            CaptureConfig.from_config(
                {
                    "banking_apps": [{"package": "com.bancolombia.app", "bank": "bancolombia"}],
                    "messages_apps": [],
                    "sms_sender_patterns": [{"pattern": "(unclosed", "bank": "bancolombia"}],
                }
            )

    def test_sms_sin_titulo_rechazado(self, capture: CaptureConfig) -> None:
        decision = capture.bank_for_notification(
            "com.google.android.apps.messaging", "sms_notification", None
        )
        assert decision.accepted is False
