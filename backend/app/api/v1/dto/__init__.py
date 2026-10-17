"""DTO публичного API версии 1."""

from app.api.v1.dto.assessment import AssessmentResponse
from app.api.v1.dto.auth import (
    TelegramAuthRequest,
    TelegramAuthResponse,
    UserResponse,
)
from app.api.v1.dto.common import ApiSchema, ErrorResponse, Score
from app.api.v1.dto.exercise import ExerciseResponse
from app.api.v1.dto.progress import ProgressResponse, WeakPhonemeResponse

__all__ = [
    "ApiSchema",
    "AssessmentResponse",
    "ErrorResponse",
    "ExerciseResponse",
    "ProgressResponse",
    "Score",
    "TelegramAuthRequest",
    "TelegramAuthResponse",
    "UserResponse",
    "WeakPhonemeResponse",
]
