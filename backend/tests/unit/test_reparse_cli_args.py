"""Tests unitarios de los argumentos del CLI `finanzia.tools.reparse` (spec 005 §7)."""

from datetime import date, datetime, timedelta, timezone
from uuid import UUID

import pytest

from finanzia.tools import reparse

pytestmark = pytest.mark.unit


def test_since_es_la_medianoche_de_bogota() -> None:
    assert reparse.since_to_datetime(date(2026, 9, 1)) == datetime(
        2026, 9, 1, tzinfo=timezone(timedelta(hours=-5))
    )


def test_sin_argumentos_no_filtra_y_usa_el_limite_por_defecto() -> None:
    args = reparse.parse_args([])

    assert (args.since, args.user, args.limit) == (None, None, 500)


def test_argumentos_validos() -> None:
    user = "4b0ef502-f2e5-4878-8c89-2b4d1e3d863b"

    args = reparse.parse_args(["--since", "2026-09-01", "--user", user, "--limit", "10"])

    assert (args.since, args.user, args.limit) == (date(2026, 9, 1), UUID(user), 10)


@pytest.mark.parametrize(
    "argv", [["--since", "01/09/2026"], ["--user", "no-es-uuid"], ["--limit", "0"]]
)
def test_argumento_invalido_termina_con_error_de_uso(argv: list[str]) -> None:
    with pytest.raises(SystemExit) as exc:
        reparse.parse_args(argv)
    assert exc.value.code == 2
