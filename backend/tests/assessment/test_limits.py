"""Тесты лимита частоты оценок."""

import unittest

from app.assessment.limits import MinuteRateLimiter


class MinuteRateLimiterTests(unittest.TestCase):
    """Скользящее окно на пользователя."""

    def test_blocks_after_limit_and_recovers(self) -> None:
        limiter = MinuteRateLimiter(limit=2)

        self.assertTrue(limiter.try_acquire(1, now=0))
        self.assertTrue(limiter.try_acquire(1, now=1))
        self.assertFalse(limiter.try_acquire(1, now=2))
        self.assertTrue(limiter.try_acquire(2, now=2))
        self.assertTrue(limiter.try_acquire(1, now=61))

    def test_zero_disables_limit(self) -> None:
        limiter = MinuteRateLimiter(limit=0)

        self.assertTrue(all(limiter.try_acquire(1, now=0) for _ in range(100)))
