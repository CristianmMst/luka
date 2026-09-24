"""gmail_connections_email_idx

Revision ID: 0006
Revises: 0005
Create Date: 2026-09-24 18:00:00.000000

El webhook push de Gmail (spec 005 §4, F3.4) solo trae `emailAddress`: resuelve
el usuario con `WHERE email = ? AND status = 'active'` en cada aviso. Sin
indice seria un seq scan por push.
"""

from collections.abc import Sequence

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0006"
down_revision: str | None = "0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema: indice por `email` en `gmail_connections`."""
    op.create_index("ix_gmail_connections_email", "gmail_connections", ["email"])


def downgrade() -> None:
    """Downgrade schema: quita el indice por `email`."""
    op.drop_index("ix_gmail_connections_email", table_name="gmail_connections")
