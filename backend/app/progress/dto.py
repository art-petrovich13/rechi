"""Внутренние структуры прогресса пользователя."""

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class WeakPhoneme:
    """Звук с низким средним по последним попыткам."""

    phoneme: str
    avg_score: int
    # Изменение среднего относительно предыдущего окна; None, если сравнивать не с чем.
    trend: int | None = None
    samples: int = 0


@dataclass(frozen=True, slots=True)
class ProgressSummary:
    """Сводка попыток пользователя."""

    attempts_count: int
    weak_phonemes: list[WeakPhoneme]
