"""DTO упражнений."""

from pydantic import Field

from app.api.v1.dto.common import ApiSchema
from app.exercises.dto import ExerciseCategory


class ExerciseResponse(ApiSchema):
    """Следующее упражнение для пользователя."""

    id: int = Field(ge=1)
    text: str = Field(min_length=1)
    phonemes: list[str]
    difficulty: int = Field(ge=1)
    category: ExerciseCategory
