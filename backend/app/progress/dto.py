"""Внутренние структуры прогресса пользователя."""

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class WeakPhoneme:
    """Фонема с низким средним результатом."""

    phoneme: str
    avg_score: int


@dataclass(frozen=True, slots=True)
class ProgressSummary:
    """Сводка всех попыток пользователя."""

    attempts_count: int
    weak_phonemes: list[WeakPhoneme]
