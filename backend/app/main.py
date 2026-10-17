from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.v1.router import router as api_v1_router
from app.bot.lifecycle import start_telegram_bot, stop_telegram_bot
from app.bot.webhook import router as bot_router
from app.core.config import settings


@asynccontextmanager
async def lifespan(application: FastAPI) -> AsyncIterator[None]:
    """Управляет жизненным циклом Telegram-бота."""

    runtime = await start_telegram_bot(settings)
    application.state.telegram_bot_runtime = runtime
    try:
        yield
    finally:
        await stop_telegram_bot(runtime)


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug,
    lifespan=lifespan,
)

app.include_router(api_v1_router)
app.include_router(bot_router)


@app.get("/health", tags=["system"])
async def health() -> dict[str, str]:
    """Проверяет, что API запущен и готов принимать запросы."""

    return {"status": "ok"}
