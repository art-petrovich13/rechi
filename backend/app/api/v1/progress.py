"""HTTP API прогресса пользователя."""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.auth import get_current_user
from app.api.dependencies.db import get_db
from app.api.v1.dto.progress import ProgressResponse, WeakPhonemeResponse
from app.data.models import User
from app.progress.service import get_user_progress


router = APIRouter(tags=["progress"])


@router.get("/progress", response_model=ProgressResponse)
async def get_progress(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ProgressResponse:
    """Возвращает число попыток и слабые фонемы текущего пользователя."""

    summary = await get_user_progress(db, current_user)
    return ProgressResponse(
        attempts_count=summary.attempts_count,
        weak_phonemes=[
            WeakPhonemeResponse(
                phoneme=item.phoneme,
                avg_score=item.avg_score,
            )
            for item in summary.weak_phonemes
        ],
    )
