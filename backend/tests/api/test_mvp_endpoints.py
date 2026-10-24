"""Контрактные тесты endpoint оценки и прогресса."""

import io
import unittest
import wave
from unittest.mock import AsyncMock, MagicMock

from fastapi.testclient import TestClient

from app.api.dependencies.auth import get_current_user
from app.api.dependencies.db import get_db
from app.api.dependencies.speechsuper import get_speech_super_client
from app.data.models import Exercise, User
from app.integrations.speechsuper.dto import SpeechAssessment, WordAssessment
from app.main import app


class MvpEndpointTests(unittest.TestCase):
    """Проверяет HTTP-контракты без PostgreSQL и внешней сети."""

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    def test_assess_returns_result_and_saves_attempt(self) -> None:
        db = MagicMock()
        db.get = AsyncMock(
            return_value=Exercise(id=5, text="рыба", phonemes=["Р", "Ы"])
        )
        db.commit = AsyncMock()
        speech_super = MagicMock()
        speech_super.assess_word = AsyncMock(
            return_value=SpeechAssessment(
                score=78,
                phoneme_scores={"Р": 55, "Ы": 91},
                words=(
                    WordAssessment(
                        text="рыба",
                        score=78,
                        phoneme_scores={"Р": 55, "Ы": 91},
                    ),
                ),
            )
        )
        self._override_dependencies(db, speech_super)

        with TestClient(app) as client:
            response = client.post(
                "/api/v1/assess",
                data={"exercise_id": "5"},
                files={"audio": ("recording.wav", _wav_bytes(), "audio/wav")},
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                "score": 78,
                "phoneme_scores": {"Р": 55, "Ы": 91},
                "problematic": ["Р"],
                "words": [
                    {
                        "text": "рыба",
                        "score": 78,
                        "phoneme_scores": {"Р": 55, "Ы": 91},
                    }
                ],
            },
        )
        db.commit.assert_awaited_once()

    def test_next_exercise_returns_category(self) -> None:
        db = MagicMock()
        db.scalar = AsyncMock(
            return_value=Exercise(
                id=16,
                text="мама мыла раму",
                phonemes=["М", "А", "Ы", "Л", "Р", "У"],
                difficulty=2,
                category="phrase",
            )
        )
        self._override_dependencies(db, MagicMock())

        with TestClient(app) as client:
            response = client.get("/api/v1/exercises/next?category=phrase")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["category"], "phrase")
        self.assertEqual(response.json()["text"], "мама мыла раму")

    def test_progress_returns_aggregated_weak_phonemes(self) -> None:
        db = MagicMock()
        db.scalars = AsyncMock(
            return_value=[{"Р": 40, "Ы": 90}, {"Р": 60, "Ы": 80}]
        )
        self._override_dependencies(db, MagicMock())

        with TestClient(app) as client:
            response = client.get("/api/v1/progress")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                "attempts_count": 2,
                "weak_phonemes": [{"phoneme": "Р", "avg_score": 50}],
            },
        )

    @staticmethod
    def _override_dependencies(db: MagicMock, speech_super: MagicMock) -> None:
        async def override_db():
            yield db

        async def override_current_user() -> User:
            return User(id=3, telegram_id=123)

        async def override_speech_super():
            return speech_super

        app.dependency_overrides[get_db] = override_db
        app.dependency_overrides[get_current_user] = override_current_user
        app.dependency_overrides[get_speech_super_client] = override_speech_super


def _wav_bytes() -> bytes:
    """Формирует секунду тишины PCM16/16kHz/mono."""

    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(16_000)
        wav_file.writeframes(b"\x00\x00" * 16_000)
    return buffer.getvalue()
