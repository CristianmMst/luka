"""review_resolution_reparsed

Revision ID: 0007
Revises: 0006
Create Date: 2026-09-24 20:00:00.000000

Agrega `reparsed` al `CHECK resolution_valida` de `review_queue` (spec 005 §7):
ledger cierra asi un item abierto cuando su mensaje, reprocesado con
`finanzia.tools.reparse`, produce por fin una transaccion.

El downgrade falla si ya hay filas `reparsed` (el `CHECK` viejo no las acepta):
se prefiere eso a reescribir en silencio como se cerro un item.
"""

from collections.abc import Sequence

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0007"
down_revision: str | None = "0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_CONSTRAINT = "ck_review_queue_resolution_valida"
_PREVIOUS_RESOLUTION_VALUES = "'converted','discarded'"
_RESOLUTION_VALUES = "'converted','discarded','reparsed'"


def _replace_check(values: str) -> None:
    op.drop_constraint(op.f(_CONSTRAINT), "review_queue", type_="check")
    op.create_check_constraint(
        op.f(_CONSTRAINT), "review_queue", f"resolution IS NULL OR resolution IN ({values})"
    )


def upgrade() -> None:
    """Upgrade schema: `resolution` acepta `reparsed`."""
    _replace_check(_RESOLUTION_VALUES)


def downgrade() -> None:
    """Downgrade schema: vuelve al `CHECK` de 0003 (`converted`/`discarded`)."""
    _replace_check(_PREVIOUS_RESOLUTION_VALUES)
