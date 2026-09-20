"""API publica de identity: unico punto de entrada para otros modulos."""

from finanzia.modules.identity.events import UserDeleted
from finanzia.modules.identity.infrastructure.api.deps import get_current_user_id

__all__ = ["UserDeleted", "get_current_user_id"]
