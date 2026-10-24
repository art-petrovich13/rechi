"""DTO оценки произношения."""

from app.api.v1.dto.common import ApiSchema, Score


class WordAssessmentResponse(ApiSchema):
    """Результат одного слова."""

    text: str
    score: Score
    phoneme_scores: dict[str, Score]


class AssessmentResponse(ApiSchema):
    """Результат оценки произношения."""

    score: Score
    phoneme_scores: dict[str, Score]
    problematic: list[str]
    words: list[WordAssessmentResponse]
