"""Бизнес-логика оценки произношения."""

from sqlalchemy.ext.asyncio import AsyncSession

from app.assessment.audio.dto import ValidatedAudio
from app.assessment.dto import AssessmentResult
from app.assessment.exceptions import AssessmentExerciseNotFoundError
from app.data.models import Attempt, Exercise, User
from app.integrations.speechsuper.client import SpeechSuperClient


PROBLEMATIC_SCORE_THRESHOLD = 60


async def assess_pronunciation(
    db: AsyncSession,
    speech_super: SpeechSuperClient,
    *,
    user: User,
    exercise_id: int,
    audio: ValidatedAudio,
) -> AssessmentResult:
    """Оценивает запись через SpeechSuper и сохраняет результат попытки."""

    exercise = await db.get(Exercise, exercise_id)
    if exercise is None:
        raise AssessmentExerciseNotFoundError

    assessment = await speech_super.assess_word(audio, exercise.text, user.id)
    attempt = Attempt(
        user_id=user.id,
        exercise_id=exercise.id,
        score=assessment.score,
        phoneme_scores=assessment.phoneme_scores,
    )
    db.add(attempt)
    await db.commit()

    problematic = [
        phoneme
        for phoneme, score in sorted(
            assessment.phoneme_scores.items(),
            key=lambda item: (item[1], item[0]),
        )
        if score < PROBLEMATIC_SCORE_THRESHOLD
    ]
    return AssessmentResult(
        score=assessment.score,
        phoneme_scores=assessment.phoneme_scores,
        problematic=problematic,
    )
