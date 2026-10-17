"""Тесты агрегации прогресса пользователя."""

import unittest

from app.progress.service import build_progress_summary


class ProgressServiceTests(unittest.TestCase):
    """Проверяет расчёт слабых фонем по сохранённым попыткам."""

    def test_aggregates_and_sorts_weak_phonemes(self) -> None:
        summary = build_progress_summary(
            [
                {"Р": 40, "Ы": 90},
                {"Р": 60, "Ы": 80, "Л": 69},
            ]
        )

        self.assertEqual(summary.attempts_count, 2)
        self.assertEqual(
            [(item.phoneme, item.avg_score) for item in summary.weak_phonemes],
            [("Р", 50), ("Л", 69)],
        )

    def test_empty_progress(self) -> None:
        summary = build_progress_summary([])

        self.assertEqual(summary.attempts_count, 0)
        self.assertEqual(summary.weak_phonemes, [])
