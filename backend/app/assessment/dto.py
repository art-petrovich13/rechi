"""Внутренние структуры оценки произношения."""

from dataclasses import dataclass, field

from app.integrations.speechsuper.dto import WordAssessment


@dataclass(frozen=True, slots=True)
class AssessmentResult:
    """Результат оценки, сохранённый как попытка пользователя."""

    score: int
    phoneme_scores: dict[str, int]
    problematic: list[str]
    words: tuple[WordAssessment, ...] = field(default_factory=tuple)
    fluency: int | None = None
    rhythm: int | None = None
    pronunciation: int | None = None
    speed: float | None = None
    duration: float | None = None
