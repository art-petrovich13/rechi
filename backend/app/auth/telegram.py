"""Валидация данных авторизации Telegram Mini App."""

import hashlib
import hmac
import json
from datetime import UTC, datetime
from typing import Any
from urllib.parse import parse_qsl

from app.auth.exceptions import InvalidInitDataError
from app.core.config import settings


def validate_init_data(init_data: str) -> dict[str, Any]:
    """Проверяет подпись и срок действия Telegram Mini App initData."""

    if not settings.bot_token:
        raise RuntimeError("BOT_TOKEN is not configured")

    data = _parse_query_string(init_data)
    received_hash = data.pop("hash", None)
    if not received_hash:
        raise InvalidInitDataError("Missing hash")

    data_check_string = "\n".join(
        f"{key}={value}" for key, value in sorted(data.items())
    )
    secret_key = hmac.new(
        key=b"WebAppData",
        msg=settings.bot_token.encode(),
        digestmod=hashlib.sha256,
    ).digest()
    calculated_hash = hmac.new(
        key=secret_key,
        msg=data_check_string.encode(),
        digestmod=hashlib.sha256,
    ).hexdigest()

    if not hmac.compare_digest(calculated_hash, received_hash):
        raise InvalidInitDataError("Invalid hash")

    _validate_auth_date(data.get("auth_date"))
    data["user"] = _parse_user(data.get("user"))
    return data


def _parse_query_string(init_data: str) -> dict[str, str]:
    """Разбирает query string и запрещает повторяющиеся параметры."""

    try:
        pairs = parse_qsl(init_data, keep_blank_values=True, strict_parsing=True)
    except ValueError as error:
        raise InvalidInitDataError("Malformed initData") from error

    if not pairs or len({key for key, _ in pairs}) != len(pairs):
        raise InvalidInitDataError("Malformed initData")

    return dict(pairs)


def _validate_auth_date(value: str | None) -> None:
    """Проверяет корректность и свежесть Telegram auth_date."""

    try:
        auth_date = datetime.fromtimestamp(int(value or ""), tz=UTC)
    except (OverflowError, TypeError, ValueError) as error:
        raise InvalidInitDataError("Invalid auth_date") from error

    age = (datetime.now(UTC) - auth_date).total_seconds()
    if age < 0 or age > settings.telegram_init_data_max_age_seconds:
        raise InvalidInitDataError("Expired initData")


def _parse_user(value: str | None) -> dict[str, Any]:
    """Проверяет JSON с обязательными данными Telegram-пользователя."""

    try:
        user = json.loads(value or "")
    except (TypeError, json.JSONDecodeError) as error:
        raise InvalidInitDataError("Invalid user") from error

    if not isinstance(user, dict) or not isinstance(user.get("id"), int):
        raise InvalidInitDataError("Invalid user")

    first_name = user.get("first_name")
    if first_name is not None and not isinstance(first_name, str):
        raise InvalidInitDataError("Invalid user")

    return user
