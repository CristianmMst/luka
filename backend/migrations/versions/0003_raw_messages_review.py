"""raw_messages_review

Revision ID: 0003
Revises: 0002
Create Date: 2026-09-20 16:00:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_CHANNEL_VALUES = "'email','notification','sms_notification'"
_BANK_VALUES = "'bancolombia','nequi','davivienda','daviplata','bbva','banco_bogota','other'"
_STATUS_VALUES = "'pending','parsed','failed','discarded','reviewed'"
_REASON_VALUES = (
    "'no_template','llm_disabled','llm_budget_exceeded','llm_invalid_json',"
    "'llm_invalid_output','llm_low_confidence','llm_error','body_purged'"
)
_RESOLUTION_VALUES = "'converted','discarded'"


def upgrade() -> None:
    """Upgrade schema: `raw_messages`, `review_queue` y la FK real de evidencias."""
    op.create_table(
        "raw_messages",
        sa.Column("id", sa.Uuid(), server_default=sa.text("gen_random_uuid()"), nullable=False),
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
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("channel", sa.Text(), nullable=False),
        sa.Column("external_id", sa.Text(), nullable=False),
        sa.Column("sender", sa.Text(), nullable=False),
        sa.Column("bank", sa.Text(), nullable=True),
        sa.Column("body", sa.Text(), nullable=True),
        sa.Column("status", sa.Text(), server_default=sa.text("'pending'"), nullable=False),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("purge_after", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(f"channel IN ({_CHANNEL_VALUES})", name="channel_valido"),
        sa.CheckConstraint(f"bank IS NULL OR bank IN ({_BANK_VALUES})", name="bank_valido"),
        sa.CheckConstraint(f"status IN ({_STATUS_VALUES})", name="status_valido"),
        sa.PrimaryKeyConstraint("id", name="pk_raw_messages"),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name="fk_raw_messages_user_id_users", ondelete="CASCADE"
        ),
        sa.UniqueConstraint(
            "user_id",
            "channel",
            "external_id",
            name="uq_raw_messages_user_id_channel_external_id",
        ),
    )
    op.create_index(
        "ix_raw_messages_user_id_status", "raw_messages", ["user_id", "status"], unique=False
    )
    # Indice parcial: solo filas con `body` aun presente (F3.7 recorre esta
    # particion en vez de la tabla completa).
    op.create_index(
        "ix_raw_messages_purge_after",
        "raw_messages",
        ["purge_after"],
        unique=False,
        postgresql_where=sa.text("body IS NOT NULL"),
    )

    op.create_table(
        "review_queue",
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
        sa.Column("raw_message_id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column(
            "partial_extract",
            postgresql.JSONB(astext_type=sa.Text()),
            server_default=sa.text("'{}'"),
            nullable=False,
        ),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("resolution", sa.Text(), nullable=True),
        sa.CheckConstraint(f"reason IN ({_REASON_VALUES})", name="reason_valido"),
        sa.CheckConstraint(
            f"resolution IS NULL OR resolution IN ({_RESOLUTION_VALUES})",
            name="resolution_valida",
        ),
        sa.CheckConstraint(
            "(resolved_at IS NULL) = (resolution IS NULL)", name="resolucion_consistente"
        ),
        sa.PrimaryKeyConstraint("raw_message_id", name="pk_review_queue"),
        sa.ForeignKeyConstraint(
            ["raw_message_id"],
            ["raw_messages.id"],
            name="fk_review_queue_raw_message_id_raw_messages",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name="fk_review_queue_user_id_users", ondelete="CASCADE"
        ),
    )
    # `created_at DESC, raw_message_id DESC` para la cola de pendientes mas
    # recientes primero (mismo patron que `ix_transactions_user_id_occurred_at_id`
    # en 0002_ledger_core.py); parcial por `resolved_at IS NULL` para mantener el
    # indice pequeno frente al historial ya resuelto.
    op.create_index(
        "ix_review_queue_user_id_created_at_raw_message_id",
        "review_queue",
        ["user_id", sa.text("created_at DESC"), sa.text("raw_message_id DESC")],
        unique=False,
        postgresql_where=sa.text("resolved_at IS NULL"),
    )

    op.create_foreign_key(
        "fk_transaction_sources_raw_message_id_raw_messages",
        "transaction_sources",
        "raw_messages",
        ["raw_message_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    """Downgrade schema: dropea la FK y las 2 tablas nuevas, en orden inverso."""
    op.drop_constraint(
        "fk_transaction_sources_raw_message_id_raw_messages",
        "transaction_sources",
        type_="foreignkey",
    )
    op.drop_index("ix_review_queue_user_id_created_at_raw_message_id", table_name="review_queue")
    op.drop_table("review_queue")
    op.drop_index("ix_raw_messages_purge_after", table_name="raw_messages")
    op.drop_index("ix_raw_messages_user_id_status", table_name="raw_messages")
    op.drop_table("raw_messages")
