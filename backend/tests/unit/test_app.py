"""Unit tests de `create_app`: OpenAPI/docs apagados en prod (review final, item H)."""

import pytest

from finanzia.app import create_app
from finanzia.shared.settings import Settings

_DEV_SETTINGS = Settings(
    _env_file=None,  # pyright: ignore[reportCallIssue]
    env="dev",
    database_url="postgresql+asyncpg://finanzia:finanzia@localhost:5432/finanzia_test_unused",
    redis_url="redis://localhost:6379/1",
    jwt_secret="test-secret-test-secret-test-secret-1234",
    google_client_id="test-client",
)


@pytest.mark.unit
def test_prod_apaga_docs_redoc_y_openapi() -> None:
    settings = _DEV_SETTINGS.model_copy(update={"env": "prod", "db_echo": False})
    app = create_app(settings)

    assert app.openapi_url is None
    assert app.docs_url is None
    assert app.redoc_url is None


@pytest.mark.unit
def test_dev_mantiene_docs_redoc_y_openapi() -> None:
    app = create_app(_DEV_SETTINGS)

    assert app.openapi_url == "/openapi.json"
    assert app.docs_url == "/docs"
    assert app.redoc_url == "/redoc"


@pytest.mark.unit
def test_test_env_mantiene_docs_redoc_y_openapi() -> None:
    settings = _DEV_SETTINGS.model_copy(update={"env": "test"})
    app = create_app(settings)

    assert app.openapi_url == "/openapi.json"
