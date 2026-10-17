"""Тесты клавиатур Telegram-бота."""

import unittest

from app.bot.keyboards import create_mini_app_keyboard


class BotKeyboardTests(unittest.TestCase):
    """Проверяет кнопку открытия Mini App."""

    def test_builds_mini_app_url(self) -> None:
        keyboard = create_mini_app_keyboard("https://rechi.example/")

        button = keyboard.inline_keyboard[0][0]
        self.assertEqual(button.text, "Начать тренировку")
        self.assertIsNotNone(button.web_app)
        self.assertEqual(button.web_app.url, "https://rechi.example/app")
