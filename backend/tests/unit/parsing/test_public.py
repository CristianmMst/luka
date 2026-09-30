"""Tests unitarios de la fachada publica de parsing (D6)."""

import pytest

from luka.modules.parsing import public
from luka.modules.parsing.domain.allowlist import NotificationDecision
from luka.modules.parsing.domain.errors import ParsingError


@pytest.mark.unit
class TestPublicFacade:
    def test_bank_for_email_sender_bancolombia(self) -> None:
        assert (
            public.bank_for_email_sender("alertasynotificaciones@an.notificacionesbancolombia.com")
            == "bancolombia"
        )

    def test_bank_for_email_sender_no_soportado(self) -> None:
        assert public.bank_for_email_sender("nu@nu.com.co") is None

    def test_bank_for_notification_bancolombia(self) -> None:
        decision = public.bank_for_notification("com.bancolombia.app", "notification", None)
        assert isinstance(decision, NotificationDecision)
        assert decision.accepted is True
        assert decision.bank == "bancolombia"

    def test_bank_for_notification_no_soportado(self) -> None:
        decision = public.bank_for_notification("com.whatsapp", "notification", None)
        assert decision.accepted is False

    def test_capture_config_incluye_yaml_crudo_y_email_senders(self) -> None:
        config = public.capture_config()
        assert config["version"] == 1
        assert "banking_apps" in config
        assert "messages_apps" in config
        assert "sms_sender_patterns" in config
        assert "bancolombia" in config["email_senders"]
        assert (
            "alertasynotificaciones@an.notificacionesbancolombia.com"
            in config["email_senders"]["bancolombia"]
        )

    def test_parsing_error_reexportado(self) -> None:
        assert issubclass(public.ParsingError, Exception)
        assert public.ParsingError is ParsingError
