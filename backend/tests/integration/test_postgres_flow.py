"""Сквозные сценарии на настоящем PostgreSQL.

Запуск: RECHI_INTEGRATION=1, DATABASE_URL указывает на базу с суффиксом
«_test», миграции применены (alembic upgrade head). Тест очищает таблицы
пользователей и попыток.
"""

import asyncio
import hashlib
import hmac
import io
import json
import os
import time
import unittest
import urllib.parse
import wave
from unittest.mock import patch

import httpx
from sqlalchemy import text
from sqlalchemy.engine import make_url

from app.api.dependencies.speechsuper import get_speech_super_client
from app.assessment.limits import MinuteRateLimiter
from app.core.config import settings
from app.data.db import engine
from app.integrations.speechsuper.dto import SpeechAssessment, WordAssessment
from app.main import app
from seed import seed_exercises


ENABLED = os.environ.get("RECHI_INTEGRATION") == "1"


def _signed_init_data(telegram_id: int) -> str:
    fields = {
        "auth_date": str(int(time.time())),
        "query_id": "integration",
        "user": json.dumps({"id": telegram_id, "first_name": "Тест"}),
    }
    check = "\n".join(f"{key}={value}" for key, value in sorted(fields.items()))
    secret = hmac.new(b"WebAppData", settings.bot_token.encode(), hashlib.sha256)
    fields["hash"] = hmac.new(
        secret.digest(), check.encode(), hashlib.sha256
    ).hexdigest()
    return urllib.parse.urlencode(fields)


def _wav() -> bytes:
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(16_000)
        wav_file.writeframes((8000).to_bytes(2, "little", signed=True) * 16_000)
    return buffer.getvalue()


class FakeSpeechSuper:
    """Оценивает всё одинаково низко и умеет отвечать с задержкой."""

    score = 5
    delay = 0.0

    async def assess_word(self, audio: object, text: str, user_id: int) -> SpeechAssessment:
        if self.delay:
            await asyncio.sleep(self.delay)
        scores = {"Р": self.score, "А": self.score}
        return SpeechAssessment(
            score=self.score,
            phoneme_scores=scores,
            words=(WordAssessment(text, self.score, scores),),
            fluency=70,
            rhythm=60,
        )


@unittest.skipUnless(ENABLED, "set RECHI_INTEGRATION=1 to run against PostgreSQL")
class PostgresFlowTests(unittest.IsolatedAsyncioTestCase):
    """Сценарии, которые раньше ломались только на реальной базе."""

    async def asyncSetUp(self) -> None:
        database = make_url(settings.database_url).database or ""
        if not database.endswith("_test"):
            self.fail(f"Refusing to clean non-test database {database!r}")
        async with engine.begin() as connection:
            await connection.execute(text("TRUNCATE attempts, users RESTART IDENTITY"))
        await seed_exercises()

        self.speech = FakeSpeechSuper()

        async def speech_dependency():
            yield self.speech

        app.dependency_overrides[get_speech_super_client] = speech_dependency
        for target, value in (
            ("app.main.validate_settings", lambda _: None),
            ("app.api.v1.assessment.minute_limiter", MinuteRateLimiter(0)),
        ):
            patcher = patch(target, value)
            patcher.start()
            self.addCleanup(patcher.stop)

        transport = httpx.ASGITransport(app=app)
        self.client = httpx.AsyncClient(transport=transport, base_url="http://test")
        response = await self.client.post(
            "/api/v1/auth/telegram", json={"initData": _signed_init_data(77)}
        )
        self.assertEqual(response.status_code, 200)
        self.headers = {"Authorization": f"Bearer {response.json()['token']}"}

    async def asyncTearDown(self) -> None:
        await self.client.aclose()
        app.dependency_overrides.clear()
        await engine.dispose()

    async def _next(self, **params: object) -> httpx.Response:
        return await self.client.get(
            "/api/v1/exercises/next", params=params, headers=self.headers
        )

    async def _assess(self, exercise_id: int) -> httpx.Response:
        return await self.client.post(
            "/api/v1/assess",
            data={"exercise_id": str(exercise_id)},
            files={"audio": ("recording.wav", _wav(), "audio/wav")},
            headers=self.headers,
        )

    async def test_failed_exercise_returns_and_training_never_ends(self) -> None:
        first = (await self._next(category="word")).json()
        self.assertEqual((await self._assess(first["id"])).status_code, 200)

        seen_again = False
        for _ in range(60):
            response = await self._next(category="word")
            self.assertEqual(response.status_code, 200)
            exercise = response.json()
            if exercise["id"] == first["id"]:
                self.assertEqual(exercise["reason"], "repeat")
                seen_again = True
            await self._assess(exercise["id"])

        self.assertTrue(seen_again)
        focus = await self._next(category="word", focus="Р")
        self.assertEqual(focus.status_code, 200)
        self.assertIn("Р", focus.json()["phonemes"])

    async def test_skipped_exercises_accumulate(self) -> None:
        ids: list[int] = []
        for _ in range(3):
            response = await self.client.get(
                "/api/v1/exercises/next",
                params=[("category", "word"), *(("exclude_id", i) for i in ids)],
                headers=self.headers,
            )
            ids.append(response.json()["id"])

        self.assertEqual(len(set(ids)), 3)

    async def test_progress_and_history_keep_metrics(self) -> None:
        exercise = (await self._next(category="phrase")).json()
        await self._assess(exercise["id"])

        progress = (await self.client.get("/api/v1/progress", headers=self.headers)).json()
        self.assertEqual(progress["attempts_count"], 1)
        self.assertEqual(progress["weak_phonemes"][0]["avg_score"], 5)

        history = (await self.client.get("/api/v1/history", headers=self.headers)).json()
        self.assertEqual(history["attempts"][0]["fluency"], 70)
        self.assertEqual(history["attempts"][0]["rhythm"], 60)

    async def test_profile_audience_filters_and_delete_removes_history(self) -> None:
        response = await self.client.patch(
            "/api/v1/me",
            json={"audience": "child", "consent_version": 1},
            headers=self.headers,
        )
        self.assertEqual(response.json()["audience"], "child")

        audiences = set()
        for _ in range(15):
            exercise = (await self._next(category="sentence")).json()
            audiences.add(exercise["audience"])
            await self._assess(exercise["id"])
        self.assertLessEqual(audiences, {"all", "child"})

        deleted = await self.client.delete("/api/v1/me", headers=self.headers)
        self.assertEqual(deleted.status_code, 204)
        async with engine.connect() as connection:
            left = await connection.scalar(text("SELECT count(*) FROM attempts"))
        self.assertEqual(left, 0)
        gone = await self.client.get("/api/v1/me", headers=self.headers)
        self.assertEqual(gone.status_code, 401)

    async def test_database_connection_is_free_during_speech_call(self) -> None:
        exercise = (await self._next()).json()
        self.speech.delay = 0.5

        tasks = [asyncio.create_task(self._assess(exercise["id"])) for _ in range(8)]
        await asyncio.sleep(0.3)
        async with engine.connect() as connection:
            hanging = await connection.scalar(
                text(
                    "SELECT count(*) FROM pg_stat_activity "
                    "WHERE datname = current_database() "
                    "AND state = 'idle in transaction'"
                )
            )
        responses = await asyncio.gather(*tasks)

        self.assertEqual(hanging, 0)
        self.assertEqual({response.status_code for response in responses}, {200})
