"""Tests unitarios de `Settings`: prefijo de entorno y validadores (spec 003 F0.4)."""

from pathlib import Path

import pytest
from pydantic import ValidationError

from finanzia.shared.settings import Settings

#: `backend/.env.example`: su llave de ejemplo no debe valer en produccion.
_ENV_EXAMPLE = Path(__file__).resolve().parents[3] / ".env.example"

_GMAIL_TOKEN_KEY_VALIDA = "AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE="  # 32 bytes en base64

_ENV_VALIDO = {
    "FINANZIA_DATABASE_URL": "postgresql+asyncpg://finanzia:finanzia@localhost:5432/finanzia_test",
    "FINANZIA_REDIS_URL": "redis://localhost:6379/1",
    "FINANZIA_JWT_SECRET": "a" * 32,
    "FINANZIA_GOOGLE_CLIENT_ID": "test-client",
    "FINANZIA_GOOGLE_CLIENT_SECRET": "test-google-client-secret",
    "FINANZIA_GMAIL_TOKEN_KEY": _GMAIL_TOKEN_KEY_VALIDA,
}


def _setear_env_valido(monkeypatch: pytest.MonkeyPatch) -> None:
    for clave, valor in _ENV_VALIDO.items():
        monkeypatch.setenv(clave, valor)


def _construir_settings() -> Settings:
    # Los campos requeridos vienen de las variables de entorno seteadas por el test;
    # pyright no lo ve porque BaseSettings sintetiza el __init__ desde los campos.
    return Settings(_env_file=None)  # pyright: ignore[reportCallIssue]


@pytest.mark.unit
def test_lee_variables_con_prefijo_finanzia(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "test")

    settings = _construir_settings()

    assert settings.env == "test"
    assert str(settings.database_url).startswith("postgresql+asyncpg://")
    assert settings.google_client_id == "test-client"


@pytest.mark.unit
def test_jwt_secret_menor_a_32_caracteres_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_JWT_SECRET", "muy-corto")

    with pytest.raises(ValidationError):
        _construir_settings()


@pytest.mark.unit
def test_db_echo_true_en_prod_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "prod")
    monkeypatch.setenv("FINANZIA_DB_ECHO", "true")

    with pytest.raises(ValidationError):
        _construir_settings()


@pytest.mark.unit
def test_gmail_token_key_de_env_example_en_prod_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    ejemplo = next(
        line.split("=", 1)[1].strip()
        for line in _ENV_EXAMPLE.read_text(encoding="utf-8").splitlines()
        if line.startswith("FINANZIA_GMAIL_TOKEN_KEY=")
    )
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "prod")
    monkeypatch.setenv("FINANZIA_GMAIL_TOKEN_KEY", ejemplo)

    with pytest.raises(ValidationError, match=r"env\.example"):
        _construir_settings()


@pytest.mark.unit
@pytest.mark.parametrize("env", ["dev", "test"])
def test_gmail_token_key_de_env_example_fuera_de_prod_pasa(
    monkeypatch: pytest.MonkeyPatch, env: str
) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", env)
    monkeypatch.setenv("FINANZIA_GMAIL_TOKEN_KEY", "62aisewZDhTFPU8eKAYDMaVzeVR4usdqlWxZgK7Abbg=")

    assert _construir_settings().env == env


@pytest.mark.unit
def test_gmail_token_key_propia_en_prod_pasa(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "prod")

    assert _construir_settings().env == "prod"


@pytest.mark.unit
def test_valores_por_defecto(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)

    settings = _construir_settings()

    assert settings.env == "dev"
    assert settings.jwt_access_ttl_seconds == 900
    assert settings.refresh_ttl_days == 60
    assert settings.rate_limit_auth_per_minute == 10
    assert settings.rate_limit_user_per_minute == 600
    assert settings.idempotency_ttl_seconds == 86400
    assert settings.max_body_bytes == 1_048_576
    assert settings.db_pool_size == 10
    assert settings.db_echo is False
    assert settings.trust_proxy_headers is False
    assert settings.log_json is False  # env == "dev"
    assert settings.rate_limit_ingest_per_minute == 60
    assert settings.deepseek_api_key is None
    assert settings.deepseek_base_url == "https://api.deepseek.com"
    assert settings.deepseek_model == "deepseek-v4-flash"
    assert settings.llm_timeout_seconds == 20.0
    assert settings.llm_monthly_token_budget_per_user == 200_000
    assert settings.llm_confidence_threshold == 0.8
    assert settings.raw_message_retention_days == 90
    assert settings.raw_message_body_max_bytes == 8192
    assert settings.gmail_pubsub_topic == "projects/finanzia-509500/topics/gmail-push"
    assert settings.gmail_push_audience == "finanzia-gmail-push"
    assert (
        settings.gmail_push_service_account
        == "gmail-push-invoker@finanzia-509500.iam.gserviceaccount.com"
    )


@pytest.mark.unit
def test_log_json_por_defecto_es_true_fuera_de_dev(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "test")

    settings = _construir_settings()

    assert settings.log_json is True


@pytest.mark.unit
def test_deepseek_api_key_none_en_prod_no_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    """LLM deshabilitado (sin API key) es legitimo incluso en prod."""
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "prod")

    settings = _construir_settings()

    assert settings.deepseek_api_key is None


@pytest.mark.unit
@pytest.mark.parametrize("valor", ["0", "-0.1", "1.1", "2"])
def test_llm_confidence_threshold_fuera_de_rango_falla(
    monkeypatch: pytest.MonkeyPatch, valor: str
) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_LLM_CONFIDENCE_THRESHOLD", valor)

    with pytest.raises(ValidationError):
        _construir_settings()


@pytest.mark.unit
def test_llm_confidence_threshold_uno_es_valido(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_LLM_CONFIDENCE_THRESHOLD", "1")

    settings = _construir_settings()

    assert settings.llm_confidence_threshold == 1.0


@pytest.mark.unit
def test_raw_message_retention_days_menor_a_uno_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_RAW_MESSAGE_RETENTION_DAYS", "0")

    with pytest.raises(ValidationError):
        _construir_settings()


@pytest.mark.unit
def test_raw_message_body_max_bytes_menor_a_512_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_RAW_MESSAGE_BODY_MAX_BYTES", "511")

    with pytest.raises(ValidationError):
        _construir_settings()


@pytest.mark.unit
def test_gmail_token_key_valida_pasa(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)

    settings = _construir_settings()

    assert settings.gmail_token_key.get_secret_value() == _GMAIL_TOKEN_KEY_VALIDA
    assert settings.google_client_secret.get_secret_value() == "test-google-client-secret"


@pytest.mark.unit
@pytest.mark.parametrize(
    "valor",
    [
        "AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB",  # 24 bytes decodificados: muy corto
        "AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE=",  # 33 bytes: muy largo
        "no-es-base64-valido-!!!",
        "",
    ],
)
def test_gmail_token_key_que_no_decodifica_a_32_bytes_falla(
    monkeypatch: pytest.MonkeyPatch, valor: str
) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_GMAIL_TOKEN_KEY", valor)

    with pytest.raises(ValidationError):
        _construir_settings()


@pytest.mark.unit
def test_los_errores_no_muestran_los_valores_de_los_secretos(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Los logs de despliegue son publicos (repo publico): un `.env` mal escrito
    no puede filtrar sus secretos en el mensaje de error (spec 009, P1)."""
    _setear_env_valido(monkeypatch)
    jwt_corto = "secreto-jwt-demasiado-corto"
    llave_rota = "no-es-base64-valido-XYZ123!!"
    database_url = "postgresql+asyncpg://finanzia:clave-db-secreta@db:5432/finanzia"
    monkeypatch.setenv("FINANZIA_JWT_SECRET", jwt_corto)
    monkeypatch.setenv("FINANZIA_GMAIL_TOKEN_KEY", llave_rota)
    monkeypatch.setenv("FINANZIA_DATABASE_URL", database_url.replace("postgresql", "mysql"))

    with pytest.raises(ValidationError) as excinfo:
        _construir_settings()

    mensaje = str(excinfo.value)
    assert "jwt_secret" in mensaje
    assert "gmail_token_key" in mensaje
    assert "database_url" in mensaje
    for secreto in (jwt_corto, llave_rota, "clave-db-secreta"):
        assert secreto not in mensaje
