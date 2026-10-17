"""Внутренние структуры интеграции SpeechSuper."""

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class SpeechAssessment:
    """Нормализованный результат оценки русского слова."""

    score: int
    phoneme_scores: dict[str, int]
