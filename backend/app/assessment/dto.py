"""Внутренние структуры оценки произношения."""

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class AssessmentResult:
    """Результат оценки, сохранённый как попытка пользователя."""

    score: int
    phoneme_scores: dict[str, int]
    problematic: list[str]
