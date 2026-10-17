"""Исключения домена авторизации."""


class InvalidInitDataError(ValueError):
    """Telegram initData отсутствует, устарела или имеет неверную подпись."""


class InvalidAccessTokenError(ValueError):
    """JWT отсутствует, повреждён, просрочен или содержит неверные данные."""
