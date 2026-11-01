"""DTO истории попыток."""

from datetime import datetime

from app.api.v1.dto.assessment import WordAssessmentResponse
from app.api.v1.dto.common import ApiSchema, Score
from app.exercises.dto import ExerciseCategory


class HistoryAttemptResponse(ApiSchema):
    """Одна попытка в истории."""

    id: int
    exercise_id: int
    exercise_text: str
    category: ExerciseCategory
    score: Score
    phoneme_scores: dict[str, Score]
    problematic: list[str]
    words: list[WordAssessmentResponse]
    created_at: datetime


class HistoryResponse(ApiSchema):
    """Последние попытки пользователя."""

    attempts: list[HistoryAttemptResponse]
