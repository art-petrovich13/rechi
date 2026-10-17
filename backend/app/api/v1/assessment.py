"""HTTP API оценки произношения."""

from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.auth import get_current_user
from app.api.dependencies.db import get_db
from app.api.dependencies.speechsuper import get_speech_super_client
from app.api.v1.dto.assessment import AssessmentResponse
from app.api.v1.dto.common import ErrorResponse
from app.assessment.audio.exceptions import AudioValidationError
from app.assessment.audio.validator import MAX_AUDIO_BYTES, validate_wav
from app.assessment.exceptions import AssessmentExerciseNotFoundError
from app.assessment.service import assess_pronunciation
from app.data.models import User
from app.integrations.speechsuper.client import SpeechSuperClient
from app.integrations.speechsuper.exceptions import (
    SpeechSuperAudioRejectedError,
    SpeechSuperError,
)


router = APIRouter(tags=["assessment"])


@router.post(
    "/assess",
    response_model=AssessmentResponse,
    responses={
        status.HTTP_400_BAD_REQUEST: {"model": ErrorResponse},
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
        status.HTTP_502_BAD_GATEWAY: {"model": ErrorResponse},
    },
)
async def assess_audio(
    audio: Annotated[UploadFile, File()],
    exercise_id: Annotated[int, Form()],
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    speech_super: Annotated[SpeechSuperClient, Depends(get_speech_super_client)],
) -> AssessmentResponse:
    """Проверяет WAV, оценивает произношение и сохраняет попытку."""

    if exercise_id < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="exercise_id must be positive",
        )

    audio_bytes = await audio.read(MAX_AUDIO_BYTES + 1)
    try:
        validated_audio = validate_wav(audio_bytes, audio.content_type)
        result = await assess_pronunciation(
            db,
            speech_super,
            user=current_user,
            exercise_id=exercise_id,
            audio=validated_audio,
        )
    except AudioValidationError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error),
        ) from error
    except AssessmentExerciseNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise not found",
        ) from error
    except SpeechSuperAudioRejectedError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Speech service rejected audio",
        ) from error
    except SpeechSuperError as error:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Speech service unavailable",
        ) from error

    return AssessmentResponse(
        score=result.score,
        phoneme_scores=result.phoneme_scores,
        problematic=result.problematic,
    )
