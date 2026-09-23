"""Pinea que los composition roots se puedan importar en un proceso limpio, sin
`finanzia.app` de por medio (fix round 1, Task 9).

`finanzia.worker` y `tests.support.pipeline` entran al modulo de parsing por su
fachada (`finanzia.modules.parsing.public`), nunca por
`infrastructure.consumers`/`infrastructure.config_loader` directo: hacerlo
dispara un import circular real (`parsing.infrastructure.consumers` ->
`parsing.infrastructure.raw_message_gateway` -> `ingestion.public` ->
`ingestion.infrastructure.sender_policy` -> `parsing.public` ->
`parsing.infrastructure.consumers`, este ultimo aun a medio inicializar) que
revienta con `ImportError: cannot import name ... from partially initialized
module`. La suite de pytest nunca lo expone porque el conftest raiz importa
`finanzia.app` (que resuelve `parsing.public` por completo) antes que
cualquier test module toque `finanzia.worker`; el unico modo real de
detectarlo es un proceso Python nuevo, sin ese import previo — exactamente lo
que arma este test (`subprocess.run`, no `importlib`: un import ya resuelto en
el proceso de pytest no vuelve a fallar).
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest

pytestmark = pytest.mark.unit

_BACKEND_DIR = Path(__file__).resolve().parents[2]
_SRC_DIR = _BACKEND_DIR / "src"

# Settings minimas para que `get_settings()` no falle por config faltante al
# importar `finanzia.worker` (que calcula `WorkerSettings.redis_settings` a
# nivel de modulo). Nunca se conecta de verdad a Redis/Postgres: el test solo
# importa el modulo, no lo ejecuta.
_REQUIRED_ENV = {
    "FINANZIA_ENV": "test",
    "FINANZIA_DATABASE_URL": "postgresql+asyncpg://finanzia:finanzia@localhost:5432/finanzia_test",
    "FINANZIA_REDIS_URL": "redis://localhost:6379/1",
    "FINANZIA_JWT_SECRET": "test-secret-test-secret-test-secret-1234",
    "FINANZIA_GOOGLE_CLIENT_ID": "test-client",
}


def _run_import(module: str) -> subprocess.CompletedProcess[str]:
    env = dict(os.environ)
    env.update(_REQUIRED_ENV)
    existing_pythonpath = env.get("PYTHONPATH")
    env["PYTHONPATH"] = (
        f"{_SRC_DIR}{os.pathsep}{existing_pythonpath}" if existing_pythonpath else str(_SRC_DIR)
    )
    return subprocess.run(  # noqa: S603 - argv fijo, sin input del usuario
        [sys.executable, "-c", f"import {module}"],
        cwd=_BACKEND_DIR,
        env=env,
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )


@pytest.mark.parametrize("module", ["finanzia.worker", "finanzia.modules.parsing.public"])
def test_import_en_proceso_limpio_no_revienta_por_ciclo(module: str) -> None:
    result = _run_import(module)
    assert result.returncode == 0, (
        f"`import {module}` fallo en un proceso limpio (sin finanzia.app previo):\n{result.stderr}"
    )
