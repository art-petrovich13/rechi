"""Inline-клавиатуры Telegram-бота."""

from aiogram.types import InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo


def create_mini_app_keyboard(public_url: str) -> InlineKeyboardMarkup:
    """Создаёт кнопку, открывающую Telegram Mini App."""

    mini_app_url = f"{public_url.rstrip('/')}/app"
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [
                InlineKeyboardButton(
                    text="Начать тренировку",
                    web_app=WebAppInfo(url=mini_app_url),
                )
            ]
        ]
    )
