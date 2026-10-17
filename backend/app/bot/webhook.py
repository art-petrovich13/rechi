"""HTTP endpoint для обновлений Telegram Bot API."""

import hmac
from typing import Any

from aiogram.types import Update
from fastapi import APIRouter, Header, HTTPException, Request, status

from app.bot.lifecycle import TelegramBotRuntime
from app.core.config import settings


router = APIRouter(prefix="/bot", tags=["bot"])


@router.post("/webhook", include_in_schema=False)
async def telegram_webhook(
    payload: dict[str, Any],
    request: Request,
    telegram_secret: str | None = Header(
        default=None,
        alias="X-Telegram-Bot-Api-Secret-Token",
    ),
) -> dict[str, bool]:
    """Передаёт полученное Telegram-обновление в aiogram Dispatcher."""

    runtime: TelegramBotRuntime | None = getattr(
        request.app.state,
        "telegram_bot_runtime",
        None,
    )
    if runtime is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Telegram bot is not configured",
        )

    _validate_webhook_secret(telegram_secret)
    update = Update.model_validate(payload, context={"bot": runtime.bot})
    await runtime.dispatcher.feed_update(runtime.bot, update)
    return {"ok": True}


def _validate_webhook_secret(received_secret: str | None) -> None:
    """Проверяет секрет webhook, если он задан в настройках."""

    expected_secret = settings.telegram_webhook_secret
    if expected_secret and (
        received_secret is None
        or not hmac.compare_digest(received_secret, expected_secret)
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Telegram webhook secret",
        )
