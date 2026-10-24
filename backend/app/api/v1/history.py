"""HTTP API истории попыток."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.auth import get_current_user
from app.api.dependencies.db import get_db
from app.api.v1.dto.assessment import WordAssessmentResponse
from app.api.v1.dto.history import HistoryAttemptResponse, HistoryResponse
from app.assessment.service import problematic_phonemes
from app.data.models import User
from app.exercises.dto import ExerciseCategory
from app.history.service import get_user_history


router = APIRouter(prefix="/history", tags=["history"])


@router.get("", response_model=HistoryResponse)
async def get_history(
    limit: Annotated[int, Query(ge=1, le=50)] = 20,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> HistoryResponse:
    """Возвращает последние попытки пользователя."""

    items = await get_user_history(db, current_user, limit=limit)
    attempts = []
    for item in items:
        words = [
            WordAssessmentResponse(
                text=str(word.get("text", "")),
                score=int(word.get("score", 0)),
                phoneme_scores={
                    str(key): int(value)
                    for key, value in dict(word.get("phoneme_scores", {})).items()
                },
            )
            for word in item.words
            if isinstance(word, dict)
        ]
        attempts.append(
            HistoryAttemptResponse(
                id=item.id,
                exercise_id=item.exercise_id,
                exercise_text=item.exercise_text,
                category=ExerciseCategory(item.category),
                score=item.score,
                phoneme_scores=item.phoneme_scores,
                problematic=problematic_phonemes(item.phoneme_scores),
                words=words,
                created_at=item.created_at,
            )
        )
    return HistoryResponse(attempts=attempts)
