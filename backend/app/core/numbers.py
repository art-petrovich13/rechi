"""Числовые помощники."""

import math


def round_half_up(value: float) -> int:
    """Округляет .5 вверх, как Dart и как ожидают люди (Python округляет к чётному)."""

    return math.floor(value + 0.5)


def mean_score(scores: list[int]) -> int:
    """Средний балл, округлённый до целого."""

    return round_half_up(sum(scores) / len(scores))
