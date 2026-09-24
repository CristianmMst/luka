"""gmail_connections

Revision ID: 0005
Revises: 0004
Create Date: 2026-09-24 10:00:00.000000

Tabla 1:1 con `users` (spec 004 §2.3, F3.2): `user_id` es PK y FK a la vez, asi
que borrar el usuario borra en cascada su conexion Gmail. `refresh_token_enc`
guarda el blob AES-256-GCM (`shared/crypto/aesgcm.py`, nonce + ciphertext); el
refresh token en claro nunca se persiste (spec 009 §1/§3).
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0005"
down_revision: str | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_STATUS_VALUES = "'active','revoked','error'"


def upgrade() -> None:
    """Upgrade schema: crea `gmail_connections`."""
    op.create_table(
        "gmail_connections",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("email", sa.Text(), nullable=False),
        sa.Column("refresh_token_enc", sa.LargeBinary(), nullable=False),
        sa.Column("history_id", sa.BigInteger(), nullable=True),
        sa.Column("watch_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.Text(), server_default=sa.text("'active'"), nullable=False),
        sa.Column("last_sync_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(f"status IN ({_STATUS_VALUES})", name="status_valido"),
        sa.PrimaryKeyConstraint("user_id", name="pk_gmail_connections"),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_gmail_connections_user_id_users",
            ondelete="CASCADE",
        ),
    )


def downgrade() -> None:
    """Downgrade schema: dropea `gmail_connections`."""
    op.drop_table("gmail_connections")
