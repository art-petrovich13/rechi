"""Запуск и остановка Telegram-бота вместе с FastAPI."""

import logging
from dataclasses import dataclass

from aiogram import Bot, Dispatcher
from aiogram.types import BotCommand

from app.bot.dispatcher import create_dispatcher
from app.core.config import Settings


logger = logging.getLogger(__name__)


@dataclass(frozen=True, slots=True)
class TelegramBotRuntime:
    """Активные объекты Telegram-бота."""

    bot: Bot
    dispatcher: Dispatcher


async def start_telegram_bot(config: Settings) -> TelegramBotRuntime | None:
    """Регистрирует команды и webhook, если бот полностью настроен."""

    if not config.bot_token or not config.public_url:
        logger.info("Telegram bot is disabled: BOT_TOKEN or PUBLIC_URL is missing")
        return None

    bot = Bot(token=config.bot_token)
    dispatcher = create_dispatcher()
    try:
        await bot.set_my_commands(
            [
                BotCommand(command="start", description="Начать тренировку"),
                BotCommand(command="help", description="Помощь"),
            ]
        )
        webhook_options: dict[str, object] = {
            "url": config.telegram_webhook_url,
            "allowed_updates": dispatcher.resolve_used_update_types(),
        }
        if config.telegram_webhook_secret:
            webhook_options["secret_token"] = config.telegram_webhook_secret
        await bot.set_webhook(**webhook_options)
    except Exception:
        await bot.session.close()
        raise

    logger.info("Telegram webhook registered at %s", config.telegram_webhook_url)
    return TelegramBotRuntime(bot=bot, dispatcher=dispatcher)


async def stop_telegram_bot(runtime: TelegramBotRuntime | None) -> None:
    """Закрывает HTTP-сессию бота при остановке приложения."""

    if runtime is not None:
        await runtime.bot.session.close()
