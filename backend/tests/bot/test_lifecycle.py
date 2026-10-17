"""Тесты жизненного цикла Telegram-бота."""

import unittest
from unittest.mock import AsyncMock, MagicMock, patch

from app.bot.lifecycle import start_telegram_bot, stop_telegram_bot
from app.core.config import Settings


class BotLifecycleTests(unittest.IsolatedAsyncioTestCase):
    """Проверяет настройку webhook без обращения к Telegram."""

    async def test_bot_stays_disabled_without_public_url(self) -> None:
        runtime = await start_telegram_bot(
            Settings(bot_token="123456:fake-token", public_url="")
        )

        self.assertIsNone(runtime)

    @patch("app.bot.lifecycle.Bot")
    async def test_registers_commands_and_webhook(self, bot_class: MagicMock) -> None:
        bot = MagicMock()
        bot.set_my_commands = AsyncMock()
        bot.set_webhook = AsyncMock()
        bot.session.close = AsyncMock()
        bot_class.return_value = bot
        config = Settings(
            bot_token="123456:fake-token",
            public_url="https://rechi.example/",
            telegram_webhook_secret="webhook-secret",
        )

        runtime = await start_telegram_bot(config)

        self.assertIsNotNone(runtime)
        bot.set_my_commands.assert_awaited_once()
        webhook_arguments = bot.set_webhook.await_args.kwargs
        self.assertEqual(
            webhook_arguments["url"],
            "https://rechi.example/bot/webhook",
        )
        self.assertEqual(webhook_arguments["secret_token"], "webhook-secret")

        await stop_telegram_bot(runtime)
        bot.session.close.assert_awaited_once()
