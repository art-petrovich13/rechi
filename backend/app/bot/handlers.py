"""Обработчики команд Telegram-бота."""

from aiogram import Router
from aiogram.filters import Command, CommandStart
from aiogram.types import Message

from app.bot.keyboards import create_mini_app_keyboard
from app.core.config import settings


router = Router(name="rechi")


@router.message(CommandStart())
async def handle_start(message: Message) -> None:
    """Приветствует пользователя и показывает кнопку Mini App."""

    await message.answer(
        "Привет! Я помогу тренировать произношение. "
        "Нажмите кнопку ниже, чтобы начать занятие.",
        reply_markup=create_mini_app_keyboard(settings.public_url),
    )


@router.message(Command("help"))
async def handle_help(message: Message) -> None:
    """Объясняет пользователю, как начать тренировку."""

    await message.answer(
        "Используйте /start, затем нажмите «Начать тренировку». "
        "В приложении выберите упражнение и запишите произношение."
    )
