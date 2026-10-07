"""drop_nfc_channel

Revision ID: 0013
Revises: 0012
Create Date: 2026-10-07 12:00:00.000000

Se retiran los tags NFC (F4.5b): las fuentes `nfc` pasan a `manual`, que es lo
que eran (un registro a mano desde el formulario rapido), y `channel_valido`
deja de aceptar `nfc`.
"""

from collections.abc import Sequence

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0013"
down_revision: str | None = "0012"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_CONSTRAINT = "ck_transaction_sources_channel_valido"
_PREVIOUS_CHANNEL_VALUES = "'email','notification','sms_notification','manual','nfc'"
_CHANNEL_VALUES = "'email','notification','sms_notification','manual'"


def _replace_check(values: str) -> None:
    op.drop_constraint(op.f(_CONSTRAINT), "transaction_sources", type_="check")
    op.create_check_constraint(op.f(_CONSTRAINT), "transaction_sources", f"channel IN ({values})")


def upgrade() -> None:
    """Upgrade schema: las fuentes `nfc` pasan a `manual` y el `CHECK` deja de aceptarlo."""
    op.execute("UPDATE transaction_sources SET channel = 'manual' WHERE channel = 'nfc'")
    _replace_check(_CHANNEL_VALUES)


def downgrade() -> None:
    """Downgrade schema: vuelve al `CHECK` de 0002 (las filas siguen en `manual`)."""
    _replace_check(_PREVIOUS_CHANNEL_VALUES)
