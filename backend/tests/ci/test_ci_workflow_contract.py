"""Contrato del workflow de CI del backend (spec 002 RNF-7, spec 009 §8, F0.5).

Este test parsea `.github/workflows/backend-ci.yml` con PyYAML y verifica que
los jobs y pasos requeridos existan, sin necesitar Docker ni GitHub Actions.
"""

from pathlib import Path
from typing import Any

import pytest
import yaml

REPO_ROOT = Path(__file__).resolve().parents[3]
WORKFLOW_PATH = REPO_ROOT / ".github" / "workflows" / "backend-ci.yml"


def _cargar_workflow() -> dict[Any, Any]:
    contenido = WORKFLOW_PATH.read_text(encoding="utf-8")
    workflow: dict[Any, Any] = yaml.safe_load(contenido)
    return workflow


def _pasos_run(job: dict[str, Any]) -> list[str]:
    """Concatena todos los bloques `run:` de los steps de un job en un solo texto."""
    steps = job.get("steps", [])
    return [str(step["run"]) for step in steps if "run" in step]


def _steps_usan(job: dict[str, Any], accion: str) -> bool:
    steps = job.get("steps", [])
    return any(str(step.get("uses", "")).startswith(accion) for step in steps)


@pytest.mark.ci
def test_workflow_existe_y_es_yaml_valido() -> None:
    assert WORKFLOW_PATH.exists(), f"No existe {WORKFLOW_PATH}"
    workflow = _cargar_workflow()
    assert workflow is not None


@pytest.mark.ci
def test_workflow_dispara_en_push_y_pull_request_sobre_backend() -> None:
    workflow = _cargar_workflow()
    # PyYAML interpreta la clave `on:` como booleano `True`.
    on = workflow.get(True, workflow.get("on"))
    assert on is not None, "El workflow debe declarar triggers `on:`"
    assert "push" in on
    assert "pull_request" in on
    assert on["push"]["paths"] == ["backend/**", ".github/workflows/backend-ci.yml"]
    assert on["pull_request"]["paths"] == ["backend/**", ".github/workflows/backend-ci.yml"]


@pytest.mark.ci
def test_workflow_tiene_permisos_minimos_y_concurrency() -> None:
    workflow = _cargar_workflow()
    assert workflow["permissions"]["contents"] == "read"
    assert "concurrency" in workflow
    assert workflow["concurrency"]["cancel-in-progress"] is True


@pytest.mark.ci
def test_workflow_tiene_exactamente_los_cuatro_jobs() -> None:
    workflow = _cargar_workflow()
    jobs = workflow["jobs"]
    assert set(jobs.keys()) == {"lint", "test", "audit", "gitleaks"}


@pytest.mark.ci
def test_job_lint_corre_ruff_pyright_e_import_linter() -> None:
    workflow = _cargar_workflow()
    job = workflow["jobs"]["lint"]
    run_steps = " \n ".join(_pasos_run(job))

    assert "uv sync --frozen --all-groups" in run_steps
    assert "uv lock --check" in run_steps
    assert "uv run ruff check ." in run_steps
    assert "uv run ruff format --check ." in run_steps
    assert "uv run pyright" in run_steps
    assert "lint-imports" in run_steps


@pytest.mark.ci
def test_job_test_crea_bases_de_datos_y_corre_pytest_con_cobertura() -> None:
    workflow = _cargar_workflow()
    job = workflow["jobs"]["test"]
    services = job["services"]

    assert services["postgres"]["image"] == "postgres:16"
    assert services["redis"]["image"] == "redis:7"

    run_steps = " \n ".join(_pasos_run(job))
    assert "finanzia_test" in run_steps
    assert "finanzia_test_migrations" in run_steps
    assert "uv run pytest" in run_steps
    assert "--cov=finanzia" in run_steps
    assert "--cov-fail-under=90" in run_steps

    env = job.get("env", {})
    assert (
        env.get("FINANZIA_TEST_DATABASE_URL")
        == "postgresql+asyncpg://finanzia:finanzia@localhost:5432/finanzia_test"
    )
    assert env.get("FINANZIA_TEST_REDIS_URL") == "redis://localhost:6379/1"

    assert _steps_usan(job, "actions/upload-artifact")


@pytest.mark.ci
def test_job_audit_corre_pip_audit() -> None:
    workflow = _cargar_workflow()
    job = workflow["jobs"]["audit"]
    run_steps = " \n ".join(_pasos_run(job))

    assert "uv export --frozen --no-hashes --all-groups" in run_steps
    assert "pip-audit" in run_steps
    assert "--strict" in run_steps


@pytest.mark.ci
def test_job_gitleaks_usa_la_accion_oficial() -> None:
    workflow = _cargar_workflow()
    job = workflow["jobs"]["gitleaks"]

    assert _steps_usan(job, "gitleaks/gitleaks-action")
