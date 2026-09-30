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

    def test_checkouts_sin_credenciales_persistidas(self, workflow: dict[Any, Any]) -> None:
        for job in workflow["jobs"].values():
            for step in job["steps"]:
                if str(step.get("uses", "")).startswith("actions/checkout"):
                    assert step["with"]["persist-credentials"] is False

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
        # El script remoto es un archivo, no stdin: `docker compose run` se
        # comia el resto del script y el despliegue quedaba a medias.
        assert "bash -s" not in script
        assert "ssh -n vps" in script
        assert "docker logout" in script

    def test_deploy_sh_valida_migra_sin_stdin_y_verifica_el_stack(self) -> None:
        deploy_sh = (COMPOSE_PATH.parent / "deploy.sh").read_text(encoding="utf-8")
        check = deploy_sh.index("get_settings()")
        migrate = deploy_sh.index("docker compose run --rm -T migrate < /dev/null")
        up = deploy_sh.index("docker compose up -d")
        assert check < migrate < up
        assert "--wait" in deploy_sh
        assert "for service in api worker postgres redis" in deploy_sh
        # Su salida va al log publico de Actions: nunca los logs de la app.
        assert "compose logs --" not in deploy_sh
        assert 'compose logs "' not in deploy_sh


@pytest.mark.ci
class TestProductionCompose:
    def test_nada_publica_puertos(self, services: dict[str, Any]) -> None:
        # El nginx del servidor es la unica entrada (nginx-luka.conf).
        assert not [name for name, svc in services.items() if svc.get("ports")]

    def test_api_en_la_red_del_proxy_con_su_alias(self, services: dict[str, Any]) -> None:
        networks = _yaml(COMPOSE_PATH)["networks"]
        assert networks["proxy"]["external"] is True
        assert services["api"]["networks"]["proxy"]["aliases"] == ["luka-api"]
        assert "proxy" not in services["worker"]["networks"]
        conf = (COMPOSE_PATH.parent / "nginx-luka.conf").read_text(encoding="utf-8")
        assert "http://luka-api:8000" in conf
        assert "access_log off;" in conf
        assert conf.count("server_name luka.a360soft.tech;") == 2
        assert "/etc/nginx/ssl/live/luka-a360soft-tech/fullchain.pem" in conf

    def test_datos_en_red_interna(self, services: dict[str, Any]) -> None:
        networks = _yaml(COMPOSE_PATH)["networks"]
        assert networks["data"]["internal"] is True
        assert services["postgres"]["networks"] == ["data"]
        assert services["redis"]["networks"] == ["data"]

    @pytest.mark.parametrize("name", APP_SERVICES)
    def test_contenedores_de_la_app_endurecidos(self, services: dict[str, Any], name: str) -> None:
        svc = services[name]
        assert svc["read_only"] is True
        assert svc["cap_drop"] == ["ALL"]
        assert "no-new-privileges:true" in svc["security_opt"]
        assert svc["environment"]["LUKA_ENV"] == "prod"
        assert svc["image"].startswith("${LUKA_IMAGE:?")

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
