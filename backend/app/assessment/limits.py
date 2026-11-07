"""Лимиты на платные вызовы оценки речи."""

import time
from collections import defaultdict, deque
from datetime import UTC, datetime, time as day_time

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.data.models import Attempt


class MinuteRateLimiter:
    """Скользящее окно в одну минуту на пользователя.

    Хранится в памяти процесса: при нескольких воркерах лимит считается
    в каждом отдельно, для MVP с одним процессом этого достаточно.
    """

    def __init__(self, limit: int, window_seconds: float = 60.0) -> None:
        self._limit = limit
        self._window = window_seconds
        self._calls: defaultdict[int, deque[float]] = defaultdict(deque)

    def try_acquire(self, user_id: int, now: float | None = None) -> bool:
        """Учитывает вызов; False, если лимит исчерпан."""

        if self._limit <= 0:
            return True
        current = time.monotonic() if now is None else now
        calls = self._calls[user_id]
        while calls and current - calls[0] >= self._window:
            calls.popleft()
        if len(calls) >= self._limit:
            return False
        calls.append(current)
        return True


async def attempts_today(db: AsyncSession, user_id: int) -> int:
    """Число сохранённых попыток пользователя с начала суток по UTC."""

    start = datetime.combine(datetime.now(UTC).date(), day_time.min, tzinfo=UTC)
    count = await db.scalar(
        select(func.count())
        .select_from(Attempt)
        .where(Attempt.user_id == user_id, Attempt.created_at >= start)
    )
    return count or 0
