"""raw_messages_requeue_attempts

Revision ID: 0004
Revises: 0003
Create Date: 2026-09-22 10:00:00.000000

Cota del reencolado (riesgo 4 / D9): el cron `requeue_pending_raw_messages`
republicaba `RawMessageReceived` para toda fila `pending` vencida, sin limite.
Un mensaje que falla siempre (p. ej. un cuerpo que revienta el handler) se
reintentaba 5 veces por entrega, iba a la DLQ, quedaba `pending` y el cron lo
volvia a publicar cada ~15 min para siempre. Este contador acota ese ciclo: a
partir de `_MAX_REQUEUE_ATTEMPTS` republicaciones la fila pasa a `failed`.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema: contador de republicaciones en `raw_messages`."""
    op.add_column(
        "raw_messages",
        sa.Column(
            "requeue_attempts",
            sa.Integer(),
            server_default=sa.text("0"),
            nullable=False,
        ),
    )


def downgrade() -> None:
    """Downgrade schema: quita el contador."""
    op.drop_column("raw_messages", "requeue_attempts")
