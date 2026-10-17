"""Зависимости подключения к базе данных."""

from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncSession

from app.data.db import async_session_factory


async def get_db() -> AsyncIterator[AsyncSession]:
    """Открывает сессию базы данных на время обработки запроса."""

    async with async_session_factory() as session:
        yield session
