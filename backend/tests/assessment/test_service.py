"""Тесты сервиса оценки произношения."""

import unittest
from unittest.mock import AsyncMock, MagicMock

from app.assessment.audio.dto import ValidatedAudio
from app.assessment.service import assess_pronunciation
from app.data.models import Exercise, User
from app.integrations.speechsuper.dto import SpeechAssessment


class AssessmentServiceTests(unittest.IsolatedAsyncioTestCase):
    """Проверяет оценку и сохранение попытки без внешних сервисов."""

    async def test_saves_attempt_and_returns_problematic_phonemes(self) -> None:
        db = MagicMock()
        db.get = AsyncMock(
            return_value=Exercise(id=5, text="рыба", phonemes=["Р", "Ы"])
        )
        db.commit = AsyncMock()
        speech_super = MagicMock()
        speech_super.assess_word = AsyncMock(
            return_value=SpeechAssessment(
                score=78,
                phoneme_scores={"Р": 49, "Ы": 87},
            )
        )

        result = await assess_pronunciation(
            db,
            speech_super,
            user=User(id=3, telegram_id=123),
            exercise_id=5,
            audio=_validated_audio(),
        )

        self.assertEqual(result.score, 78)
        self.assertEqual(result.problematic, ["Р"])
        attempt = db.add.call_args.args[0]
        self.assertEqual(attempt.user_id, 3)
        self.assertEqual(attempt.exercise_id, 5)
        self.assertEqual(attempt.phoneme_scores, {"Р": 49, "Ы": 87})
        db.commit.assert_awaited_once()


def _validated_audio() -> ValidatedAudio:
    """Создаёт минимальный объект уже проверенного аудио."""

    return ValidatedAudio(
        data=b"audio",
        duration_seconds=1.0,
        sample_rate=16_000,
        channels=1,
        sample_width=2,
    )
