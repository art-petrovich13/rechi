"""Домен авторизации пользователей."""

from app.auth.service import AuthResult, authenticate_telegram_user

__all__ = ["AuthResult", "authenticate_telegram_user"]
