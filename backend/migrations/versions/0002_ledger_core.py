"""ledger_core

Revision ID: 0002
Revises: 0001
Create Date: 2026-09-20 15:00:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_BANK_VALUES = "'bancolombia','nequi','davivienda','daviplata','bbva','banco_bogota','other'"
_ACCOUNT_KIND_VALUES = "'savings','checking','credit_card','wallet'"
_DIRECTION_VALUES = "'debit','credit'"
_TRANSACTION_KIND_VALUES = "'expense','income','transfer'"
_CHANNEL_VALUES = "'email','notification','sms_notification','manual','nfc'"
_FISCAL_TAG_VALUES = (
    "'ingreso_laboral','ingreso_honorarios','ingreso_capital','ingreso_no_laboral',"
    "'ingreso_pension','deducible_salud','deducible_vivienda','aporte_pension_voluntaria',"
    "'aporte_afc','aporte_obligatorio','donacion','no_deducible','transferencia'"
)

# Los 24 registros literales corresponden 1:1 a
# `luka.modules.ledger.domain.system_categories.SYSTEM_CATEGORIES`. No se
# importa ese modulo aqui: las migraciones son snapshots inmutables (P8); si el
# catalogo de dominio cambia, se necesita una migracion nueva.
_SYSTEM_CATEGORIES: list[dict[str, str | None]] = [
    {
        "id": "75b936a8-d5bd-5e28-99e1-c675ac87f3e0",
        "slug": "sin_categoria",
        "name": "Sin categoría",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "d2a5c458-d8bd-5afd-8e4d-3021d827d1d7",
        "slug": "mercado",
        "name": "Mercado y supermercado",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "4bf8a593-adff-5ff2-bfdb-462ced898a59",
        "slug": "restaurantes",
        "name": "Restaurantes y domicilios",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "10cfe2df-0728-5a9a-8726-048af34f77d2",
        "slug": "transporte",
        "name": "Transporte y movilidad",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "6a5a0a65-800b-5c57-988e-9f1a2b297d4f",
        "slug": "servicios_publicos",
        "name": "Servicios públicos e internet",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "7b45ab03-5e8e-5ec2-a943-7af76bbc87e3",
        "slug": "arriendo",
        "name": "Arriendo y administración",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "2636a993-e19b-5038-a24c-7f7dec30985b",
        "slug": "compras",
        "name": "Compras y ropa",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "05f2c95a-7beb-5c41-bb68-99486b08e53f",
        "slug": "entretenimiento",
        "name": "Entretenimiento y suscripciones",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "61b4d12b-f5f0-59f5-9af8-6742345bb888",
        "slug": "salud",
        "name": "Salud y farmacia",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "0f3532a1-067d-5448-861f-9a5abe400ecb",
        "slug": "educacion",
        "name": "Educación",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "08121fd1-26c8-53d1-bc19-6ff0859a7e0d",
        "slug": "impuestos_comisiones",
        "name": "Impuestos, comisiones y cuotas de manejo",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "2087cbef-7806-5cf3-8e09-cc8ba4a5c0fc",
        "slug": "efectivo",
        "name": "Retiros de efectivo",
        "fiscal_tag": "no_deducible",
        "user_id": None,
    },
    {
        "id": "7d7c39bc-90d1-58d0-ac97-647951bc9b97",
        "slug": "medicina_prepagada",
        "name": "Medicina prepagada y seguros de salud",
        "fiscal_tag": "deducible_salud",
        "user_id": None,
    },
    {
        "id": "fe24c69f-9029-5334-b75c-9e70a72986ea",
        "slug": "credito_vivienda",
        "name": "Cuota crédito de vivienda",
        "fiscal_tag": "deducible_vivienda",
        "user_id": None,
    },
    {
        "id": "a6cfc9bd-123a-52a7-9455-f0b178c98022",
        "slug": "pension_voluntaria",
        "name": "Aportes voluntarios a pensión",
        "fiscal_tag": "aporte_pension_voluntaria",
        "user_id": None,
    },
    {
        "id": "09137b15-5a0f-5f08-ba41-ee79564729ed",
        "slug": "afc",
        "name": "Ahorro AFC",
        "fiscal_tag": "aporte_afc",
        "user_id": None,
    },
    {
        "id": "5c6516c5-0926-58cf-8546-d9e011a08a15",
        "slug": "seguridad_social",
        "name": "Salud y pensión obligatorias (PILA)",
        "fiscal_tag": "aporte_obligatorio",
        "user_id": None,
    },
    {
        "id": "29520b39-798b-51a5-af2c-15c0083f4ee3",
        "slug": "donaciones",
        "name": "Donaciones",
        "fiscal_tag": "donacion",
        "user_id": None,
    },
    {
        "id": "36db5c3b-aea3-589c-a866-1b2e075902bc",
        "slug": "nomina",
        "name": "Nómina y salario",
        "fiscal_tag": "ingreso_laboral",
        "user_id": None,
    },
    {
        "id": "0cf9a61b-109d-5a2e-8032-7dd0e552dbf5",
        "slug": "honorarios",
        "name": "Honorarios y servicios independientes",
        "fiscal_tag": "ingreso_honorarios",
        "user_id": None,
    },
    {
        "id": "1b55f7e7-a081-5466-9878-31083691969c",
        "slug": "rendimientos",
        "name": "Rendimientos, intereses y arriendos recibidos",
        "fiscal_tag": "ingreso_capital",
        "user_id": None,
    },
    {
        "id": "746501ff-31a0-5b2e-b9ab-8c86602b1332",
        "slug": "pension_recibida",
        "name": "Mesada pensional",
        "fiscal_tag": "ingreso_pension",
        "user_id": None,
    },
    {
        "id": "98709534-438d-5235-9dd8-58dbe4a755d9",
        "slug": "otros_ingresos",
        "name": "Otros ingresos",
        "fiscal_tag": "ingreso_no_laboral",
        "user_id": None,
    },
    {
        "id": "2425ca2a-3801-5fd6-8187-6c947d9db1e3",
        "slug": "transferencias",
        "name": "Transferencias entre cuentas propias",
        "fiscal_tag": "transferencia",
        "user_id": None,
    },
]


def upgrade() -> None:
    """Upgrade schema: 5 tablas del ledger + seed de las 24 categorias del sistema."""
    op.create_table(
        "categories",
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
        sa.Column("user_id", sa.Uuid(), nullable=True),
        sa.Column("slug", sa.Text(), nullable=True),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("icon", sa.Text(), nullable=True),
        sa.Column("color", sa.Text(), nullable=True),
        sa.Column("fiscal_tag", sa.Text(), nullable=False),
        sa.CheckConstraint(f"fiscal_tag IN ({_FISCAL_TAG_VALUES})", name="fiscal_tag_valido"),
        sa.CheckConstraint("(user_id IS NULL) = (slug IS NOT NULL)", name="slug_solo_sistema"),
        sa.PrimaryKeyConstraint("id", name="pk_categories"),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name="fk_categories_user_id_users", ondelete="CASCADE"
        ),
        sa.UniqueConstraint("slug", name="uq_categories_slug"),
        sa.UniqueConstraint(
            "user_id",
            "name",
            name="uq_categories_user_id_name",
            postgresql_nulls_not_distinct=True,
        ),
    )

    op.create_table(
        "linked_accounts",
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
        sa.Column("bank", sa.Text(), nullable=False),
        sa.Column("kind", sa.Text(), nullable=False),
        sa.Column("last4", sa.Text(), nullable=True),
        sa.Column("alias", sa.Text(), nullable=True),
        sa.CheckConstraint(f"bank IN ({_BANK_VALUES})", name="bank_valido"),
        sa.CheckConstraint(f"kind IN ({_ACCOUNT_KIND_VALUES})", name="kind_valido"),
        sa.CheckConstraint("last4 ~ '^[0-9]{1,4}$'", name="last4_digitos"),
        sa.PrimaryKeyConstraint("id", name="pk_linked_accounts"),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_linked_accounts_user_id_users",
            ondelete="CASCADE",
        ),
        sa.UniqueConstraint(
            "user_id",
            "bank",
            "last4",
            name="uq_linked_accounts_user_id_bank_last4",
            postgresql_nulls_not_distinct=True,
        ),
    )

    op.create_table(
        "transactions",
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
        sa.Column("amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("currency", sa.Text(), server_default=sa.text("'COP'"), nullable=False),
        sa.Column("direction", sa.Text(), nullable=False),
        sa.Column("kind", sa.Text(), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("merchant", sa.Text(), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("bank", sa.Text(), nullable=True),
        sa.Column("account_id", sa.Uuid(), nullable=True),
        sa.Column("category_id", sa.Uuid(), nullable=False),
        sa.Column("fiscal_tag", sa.Text(), nullable=False),
        sa.Column("transfer_pair_id", sa.Uuid(), nullable=True),
        sa.Column("transfer_auto", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column(
            "transfer_exclusions",
            postgresql.JSONB(astext_type=sa.Text()),
            server_default=sa.text("'[]'"),
            nullable=False,
        ),
        sa.Column("dedupe_key", sa.Text(), nullable=False),
        sa.Column("parsed_by", sa.Text(), nullable=False),
        sa.Column("confidence", sa.REAL(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.CheckConstraint("amount > 0", name="amount_positivo"),
        sa.CheckConstraint(f"direction IN ({_DIRECTION_VALUES})", name="direction_valido"),
        sa.CheckConstraint(f"kind IN ({_TRANSACTION_KIND_VALUES})", name="kind_valido"),
        sa.CheckConstraint(f"bank IS NULL OR bank IN ({_BANK_VALUES})", name="bank_valido"),
        sa.CheckConstraint(f"fiscal_tag IN ({_FISCAL_TAG_VALUES})", name="fiscal_tag_valido"),
        sa.PrimaryKeyConstraint("id", name="pk_transactions"),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name="fk_transactions_user_id_users", ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["account_id"],
            ["linked_accounts.id"],
            name="fk_transactions_account_id_linked_accounts",
            ondelete="SET NULL",
        ),
        sa.ForeignKeyConstraint(
            ["category_id"],
            ["categories.id"],
            name="fk_transactions_category_id_categories",
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["transfer_pair_id"],
            ["transactions.id"],
            name="fk_transactions_transfer_pair_id_transactions",
            ondelete="SET NULL",
        ),
        sa.UniqueConstraint("user_id", "dedupe_key", name="uq_transactions_user_id_dedupe_key"),
    )
    # `occurred_at DESC, id DESC` para paginacion por keyset hacia atras (spec 004
    # SS2.5). Se emite explicito con `sa.text(...)` porque el ORM define el mismo
    # indice via `sqlalchemy.desc(...)`: `alembic check` compara ambas formas sin
    # reportar drift (verificado en esta migracion).
    op.create_index(
        "ix_transactions_user_id_occurred_at_id",
        "transactions",
        ["user_id", sa.text("occurred_at DESC"), sa.text("id DESC")],
        unique=False,
    )
    op.create_index(
        "ix_transactions_user_id_updated_at_id",
        "transactions",
        ["user_id", "updated_at", "id"],
        unique=False,
    )
    op.create_index(
        "ix_transactions_user_id_category_id", "transactions", ["user_id", "category_id"]
    )
    op.create_index("ix_transactions_user_id_kind", "transactions", ["user_id", "kind"])
    op.create_index("ix_transactions_transfer_pair_id", "transactions", ["transfer_pair_id"])

    op.create_table(
        "transaction_sources",
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
        sa.Column("transaction_id", sa.Uuid(), nullable=False),
        # Sin FK a `raw_messages`: esa tabla llega en F2.1 (ingestion).
        sa.Column("raw_message_id", sa.Uuid(), nullable=True),
        sa.Column("channel", sa.Text(), nullable=False),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(f"channel IN ({_CHANNEL_VALUES})", name="channel_valido"),
        sa.PrimaryKeyConstraint("id", name="pk_transaction_sources"),
        sa.ForeignKeyConstraint(
            ["transaction_id"],
            ["transactions.id"],
            name="fk_transaction_sources_transaction_id_transactions",
            ondelete="CASCADE",
        ),
    )
    op.create_index(
        "uq_transaction_sources_transaction_id_raw_message_id",
        "transaction_sources",
        ["transaction_id", "raw_message_id"],
        unique=True,
        postgresql_where=sa.text("raw_message_id IS NOT NULL"),
    )
    op.create_index(
        "ix_transaction_sources_transaction_id", "transaction_sources", ["transaction_id"]
    )

    op.create_table(
        "merchant_rules",
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
        sa.Column("merchant_pattern", sa.Text(), nullable=False),
        sa.Column("category_id", sa.Uuid(), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_merchant_rules"),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name="fk_merchant_rules_user_id_users", ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["category_id"],
            ["categories.id"],
            name="fk_merchant_rules_category_id_categories",
            ondelete="CASCADE",
        ),
        sa.UniqueConstraint(
            "user_id",
            "merchant_pattern",
            name="uq_merchant_rules_user_id_merchant_pattern",
        ),
    )

    categories_table = sa.table(
        "categories",
        sa.column("id", sa.Uuid()),
        sa.column("user_id", sa.Uuid()),
        sa.column("slug", sa.Text()),
        sa.column("name", sa.Text()),
        sa.column("fiscal_tag", sa.Text()),
    )
    op.bulk_insert(categories_table, _SYSTEM_CATEGORIES)


def downgrade() -> None:
    """Downgrade schema: dropea las 5 tablas en orden inverso (el seed se va con `categories`)."""
    op.drop_table("merchant_rules")
    op.drop_index("ix_transaction_sources_transaction_id", table_name="transaction_sources")
    op.drop_index(
        "uq_transaction_sources_transaction_id_raw_message_id",
        table_name="transaction_sources",
    )
    op.drop_table("transaction_sources")
    op.drop_index("ix_transactions_transfer_pair_id", table_name="transactions")
    op.drop_index("ix_transactions_user_id_kind", table_name="transactions")
    op.drop_index("ix_transactions_user_id_category_id", table_name="transactions")
    op.drop_index("ix_transactions_user_id_updated_at_id", table_name="transactions")
    op.drop_index("ix_transactions_user_id_occurred_at_id", table_name="transactions")
    op.drop_table("transactions")
    op.drop_table("linked_accounts")
    op.drop_table("categories")
