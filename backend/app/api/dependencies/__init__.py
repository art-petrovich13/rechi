"""Переиспользуемые зависимости HTTP API."""

from app.api.dependencies.auth import get_current_user
from app.api.dependencies.db import get_db

__all__ = ["get_current_user", "get_db"]
