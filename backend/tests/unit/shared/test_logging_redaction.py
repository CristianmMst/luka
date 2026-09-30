"""Tests unitarios de redaccion de PII en logs (spec 009 SS5)."""

import logging

import pytest

from luka.shared.logging import FORBIDDEN_LOG_KEYS, configure_logging, redact_forbidden_keys
from luka.shared.settings import Settings


@pytest.mark.unit
def test_redact_forbidden_keys_reemplaza_valores_prohibidos() -> None:
    event_dict = {
        "event": "algo",
        "email": "user@example.com",
        "amount": "152300.00",
        "user_id": "u-1",
    }

    result = redact_forbidden_keys(None, "info", event_dict)

    assert result["email"] == "[redacted]"
    assert result["amount"] == "[redacted]"
    assert result["user_id"] == "u-1"
    assert set(result["redacted_keys"]) == {"email", "amount"}


@pytest.mark.unit
def test_redact_forbidden_keys_no_toca_claves_permitidas() -> None:
    event_dict = {"event": "algo", "request_id": "abc", "status": 200}

    result = redact_forbidden_keys(None, "info", dict(event_dict))

    assert result == event_dict
    assert "redacted_keys" not in result


@pytest.mark.unit
def test_forbidden_log_keys_coincide_con_el_contrato() -> None:
    assert FORBIDDEN_LOG_KEYS == frozenset(
        {
            "email",
            "email_address",
            "sender",
            "subject",
            "server_auth_code",
            "amount",
            "merchant",
            "description",
            "notes",
            "body",
            "text",
            "title",
            "token",
            "id_token",
            "access_token",
            "refresh_token",
            "token_hash",
            "payload",
            "q",
            "authorization",
        }
    )


@pytest.mark.unit
def test_configure_logging_es_idempotente(settings: Settings) -> None:
    # No asumimos un total absoluto de handlers: pytest (caplog/live-log) agrega
    # los suyos al root logger. Lo que valida la idempotencia es que una segunda
    # llamada no agregue (ni quite) ningun handler propio.
    configure_logging(settings)
    handlers_tras_primera_llamada = list(logging.getLogger().handlers)

    configure_logging(settings)
    handlers_tras_segunda_llamada = list(logging.getLogger().handlers)

    assert handlers_tras_primera_llamada == handlers_tras_segunda_llamada
