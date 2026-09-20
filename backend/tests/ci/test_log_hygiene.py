"""CI: analiza (via AST) llamadas de logging/bind que podrian filtrar PII (spec 009 SS5).

No requiere Docker. Usa `finanzia.shared.logging.FORBIDDEN_LOG_KEYS` como unica
fuente de verdad de claves prohibidas.
"""

import ast
import re
from pathlib import Path

import pytest

from finanzia.shared.logging import FORBIDDEN_LOG_KEYS

_IDENTIFIER_PATTERN = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")

_LOG_METHOD_NAMES = frozenset(
    {
        "debug",
        "info",
        "warning",
        "error",
        "exception",
        "critical",
        "bind",
        "bind_contextvars",
        "new",
    }
)

REPO_SRC = Path(__file__).resolve().parents[2] / "src" / "finanzia"


def _joined_str_referencia_clave_prohibida(node: ast.JoinedStr) -> bool:
    for value in node.values:
        if not isinstance(value, ast.FormattedValue):
            continue
        source = ast.unparse(value.value)
        identifiers = set(_IDENTIFIER_PATTERN.findall(source))
        if identifiers & FORBIDDEN_LOG_KEYS:
            return True
    return False


def _es_llamada_a_locals_o_vars(node: ast.expr) -> bool:
    return (
        isinstance(node, ast.Call)
        and isinstance(node.func, ast.Name)
        and node.func.id in {"locals", "vars"}
    )


def _violaciones_de_llamada(call: ast.Call) -> list[str]:
    razones: list[str] = []

    for keyword in call.keywords:
        if keyword.arg is not None and keyword.arg in FORBIDDEN_LOG_KEYS:
            razones.append(f"kwarg prohibido '{keyword.arg}'")
        elif keyword.arg is None and _es_llamada_a_locals_o_vars(keyword.value):
            razones.append("desempaqueta locals()/vars() con **")
        elif isinstance(keyword.value, ast.JoinedStr) and _joined_str_referencia_clave_prohibida(
            keyword.value
        ):
            razones.append(f"f-string en kwarg '{keyword.arg}' referencia clave prohibida")

    for arg in call.args:
        if isinstance(arg, ast.JoinedStr) and _joined_str_referencia_clave_prohibida(arg):
            razones.append("f-string posicional referencia clave prohibida")

    return razones


def find_violations(directory: Path) -> list[str]:
    """Escanea `directory` (recursivo) en busca de llamadas de log que filtren PII."""
    violaciones: list[str] = []
    for path in sorted(directory.rglob("*.py")):
        try:
            arbol = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        except SyntaxError:
            continue
        for node in ast.walk(arbol):
            if not isinstance(node, ast.Call) or not isinstance(node.func, ast.Attribute):
                continue
            if node.func.attr not in _LOG_METHOD_NAMES:
                continue
            for razon in _violaciones_de_llamada(node):
                violaciones.append(f"{path}:{node.lineno}: {razon}")
    return violaciones


@pytest.mark.ci
def test_codigo_de_finanzia_no_filtra_pii_en_logs() -> None:
    violaciones = find_violations(REPO_SRC)

    assert not violaciones, "Llamadas de log con posible PII:\n" + "\n".join(violaciones)


@pytest.mark.ci
def test_detector_detecta_violacion_deliberada(tmp_path: Path) -> None:
    archivo_con_violacion = tmp_path / "violacion.py"
    archivo_con_violacion.write_text(
        "import structlog\n"
        "logger = structlog.get_logger()\n"
        "logger.info('login', email='user@example.com')\n"
        "logger.info(f'hola {amount}')\n"
        "logger.bind(**locals())\n",
        encoding="utf-8",
    )

    violaciones = find_violations(tmp_path)

    assert len(violaciones) == 3
    assert all("violacion.py" in violacion for violacion in violaciones)


@pytest.mark.ci
def test_detector_no_marca_codigo_limpio(tmp_path: Path) -> None:
    archivo_limpio = tmp_path / "limpio.py"
    archivo_limpio.write_text(
        "import structlog\n"
        "logger = structlog.get_logger()\n"
        "logger.info('http_request', method='GET', status=200)\n",
        encoding="utf-8",
    )

    assert find_violations(tmp_path) == []
