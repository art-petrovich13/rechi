"""DTO оценки произношения."""

from app.api.v1.dto.common import ApiSchema, Score


class AssessmentResponse(ApiSchema):
    """Результат оценки произношения."""

    score: Score
    phoneme_scores: dict[str, Score]
    problematic: list[str]
