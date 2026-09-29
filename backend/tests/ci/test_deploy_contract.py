"""Contrato del despliegue (backend/deploy/README.md, spec 009 §8).

Parsea `.github/workflows/deploy-backend.yml`, `backend/deploy/compose.yml` y
el `Dockerfile` y verifica las reglas que no deben perderse al editarlos:
gate de seguridad antes de publicar, imagen fijada por digest, solo Caddy
expuesto, datos en una red interna y contenedores endurecidos. No necesita
Docker ni GitHub Actions.
"""

from pathlib import Path
from typing import Any

import pytest
import yaml

BACKEND = Path(__file__).resolve().parents[2]
WORKFLOW_PATH = BACKEND.parent / ".github" / "workflows" / "deploy-backend.yml"
COMPOSE_PATH = BACKEND / "deploy" / "compose.yml"
DOCKERFILE_PATH = BACKEND / "Dockerfile"

APP_SERVICES = ("api", "worker", "migrate")


def _yaml(path: Path) -> dict[Any, Any]:
    data: dict[Any, Any] = yaml.safe_load(path.read_text(encoding="utf-8"))
    return data


def _runs(job: dict[str, Any]) -> str:
    return "\n".join(str(step["run"]) for step in job.get("steps", []) if "run" in step)


def _uses(job: dict[str, Any], action: str) -> bool:
    return any(str(step.get("uses", "")).startswith(action) for step in job.get("steps", []))


@pytest.fixture
def workflow() -> dict[Any, Any]:
    return _yaml(WORKFLOW_PATH)


@pytest.fixture
def services() -> dict[str, Any]:
    return _yaml(COMPOSE_PATH)["services"]


@pytest.mark.ci
class TestDeployWorkflow:
    def test_dispara_en_main_sobre_backend_y_a_mano(self, workflow: dict[Any, Any]) -> None:
        # PyYAML interpreta la clave `on:` como booleano `True`.
        on: dict[str, Any] = workflow.get(True) or workflow["on"]
        assert on["push"]["branches"] == ["main"]
        assert on["push"]["paths"] == ["backend/**", ".github/workflows/deploy-backend.yml"]
        assert "workflow_dispatch" in on
        assert "pull_request" not in on

    def test_permisos_minimos_y_sin_cancelar_un_despliegue(self, workflow: dict[Any, Any]) -> None:
        assert workflow["permissions"] == {"contents": "read"}
        assert workflow["concurrency"]["cancel-in-progress"] is False

    def test_gate_bloquea_el_build(self, workflow: dict[Any, Any]) -> None:
        jobs = workflow["jobs"]
        assert list(jobs) == ["gate", "build", "deploy"]
        assert jobs["build"]["needs"] == "gate"
        assert jobs["deploy"]["needs"] == "build"
        gate = jobs["gate"]
        assert "pip-audit --strict" in _runs(gate)
        assert "--no-dev" in _runs(gate)
        assert _uses(gate, "gitleaks/gitleaks-action")

    def test_build_publica_con_sbom_y_procedencia(self, workflow: dict[Any, Any]) -> None:
        build = workflow["jobs"]["build"]
        assert build["permissions"]["packages"] == "write"
        push = next(
            s
            for s in build["steps"]
            if str(s.get("uses", "")).startswith("docker/build-push-action")
        )
        assert push["with"]["context"] == "backend"
        assert push["with"]["sbom"] is True
        assert push["with"]["provenance"] == "mode=max"

    def test_deploy_fija_el_digest_y_migra_antes_de_levantar(
        self, workflow: dict[Any, Any]
    ) -> None:
        deploy = workflow["jobs"]["deploy"]
        assert deploy["environment"] == "production"
        assert deploy["permissions"]["packages"] == "read"
        env = next(s for s in deploy["steps"] if s.get("name") == "Migrar y levantar")["env"]
        assert "needs.build.outputs.digest" in env["IMAGE_REF"]
        script = _runs(deploy)
        assert "StrictHostKeyChecking yes" in script
        assert "--password-stdin" in script
        assert script.index("run --rm migrate") < script.index("up -d")
        assert "--wait" in script


@pytest.mark.ci
class TestProductionCompose:
    def test_solo_caddy_publica_puertos(self, services: dict[str, Any]) -> None:
        exposed = {name for name, svc in services.items() if svc.get("ports")}
        assert exposed == {"caddy"}

    def test_datos_en_red_interna(self, services: dict[str, Any]) -> None:
        networks = _yaml(COMPOSE_PATH)["networks"]
        assert networks["data"]["internal"] is True
        assert services["postgres"]["networks"] == ["data"]
        assert services["redis"]["networks"] == ["data"]
        assert "data" not in services["caddy"]["networks"]

    @pytest.mark.parametrize("name", APP_SERVICES)
    def test_contenedores_de_la_app_endurecidos(self, services: dict[str, Any], name: str) -> None:
        svc = services[name]
        assert svc["read_only"] is True
        assert svc["cap_drop"] == ["ALL"]
        assert "no-new-privileges:true" in svc["security_opt"]
        assert svc["environment"]["FINANZIA_ENV"] == "prod"
        assert svc["image"].startswith("${FINANZIA_IMAGE:?")

    def test_migraciones_solo_a_pedido(self, services: dict[str, Any]) -> None:
        assert services["migrate"]["profiles"] == ["migrate"]
        assert services["migrate"]["command"] == ["alembic", "upgrade", "head"]

    def test_redis_persiste_el_bus_de_eventos(self, services: dict[str, Any]) -> None:
        assert "--appendonly" in services["redis"]["command"]
        assert services["redis"]["volumes"] == ["redis_data:/data"]

    def test_worker_tiene_healthcheck_de_arq(self, services: dict[str, Any]) -> None:
        assert services["worker"]["healthcheck"]["test"][:3] == ["CMD", "arq", "--check"]


@pytest.mark.ci
def test_imagen_corre_sin_root_y_multietapa() -> None:
    dockerfile = DOCKERFILE_PATH.read_text(encoding="utf-8")
    assert dockerfile.count("\nFROM ") >= 2
    assert "\nUSER app\n" in dockerfile
    assert "uv sync --frozen --no-dev" in dockerfile
    assert "HEALTHCHECK" in dockerfile
