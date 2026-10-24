"""Внутренние структуры интеграции SpeechSuper."""

from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class WordAssessment:
    """Результат одного слова в записи."""

    text: str
    score: int
    phoneme_scores: dict[str, int]


@dataclass(frozen=True, slots=True)
class SpeechAssessment:
    """Нормализованный результат оценки слова или фразы."""

    score: int
    phoneme_scores: dict[str, int]
    words: tuple[WordAssessment, ...] = field(default_factory=tuple)
