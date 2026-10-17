"""Создание диспетчера Telegram-бота."""

from aiogram import Dispatcher

from app.bot.handlers import router as handlers_router


def create_dispatcher() -> Dispatcher:
    """Создаёт Dispatcher и регистрирует обработчики проекта."""

    dispatcher = Dispatcher()
    dispatcher.include_router(handlers_router)
    return dispatcher
