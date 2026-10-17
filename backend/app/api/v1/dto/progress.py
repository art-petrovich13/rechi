"""DTO прогресса пользователя."""

from pydantic import Field

from app.api.v1.dto.common import ApiSchema, Score


class WeakPhonemeResponse(ApiSchema):
    """Фонема с низкой средней оценкой."""

    phoneme: str = Field(min_length=1)
    avg_score: Score


class ProgressResponse(ApiSchema):
    """Сводный прогресс пользователя."""

    attempts_count: int = Field(ge=0)
    weak_phonemes: list[WeakPhonemeResponse]
