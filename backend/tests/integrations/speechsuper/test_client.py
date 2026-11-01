"""Тесты HTTP-клиента SpeechSuper."""

import unittest

import httpx

from app.assessment.audio.dto import ValidatedAudio
from app.integrations.speechsuper.client import SpeechSuperClient
from app.integrations.speechsuper.exceptions import SpeechSuperUnavailableError


class SpeechSuperClientTests(unittest.IsolatedAsyncioTestCase):
    """Проверяет multipart-запрос без обращения к внешней сети."""

    async def test_sends_request_and_parses_response(self) -> None:
        async def handler(request: httpx.Request) -> httpx.Response:
            self.assertEqual(
                str(request.url),
                "https://speech.test/word.eval.ru",
            )
            self.assertEqual(request.headers["Request-Index"], "0")
            self.assertTrue(
                request.headers["Content-Type"].startswith("multipart/form-data")
            )

            body = await request.aread()
            self.assertIn(b'"coreType":"word.eval.ru"', body)
            self.assertIn("рыба".encode(), body)
            self.assertIn(b'filename="recording.wav"', body)
            self.assertNotIn(b"secret-key", body)

            return httpx.Response(
                200,
                json={
                    "result": {
                        "overall": 81,
                        "words": [
                            {
                                "phonemes": [
                                    {"phoneme": "р", "pronunciation": 55},
                                    {"phoneme": "ы", "pronunciation": 88},
                                ]
                            }
                        ],
                    }
                },
            )

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport) as http_client:
            client = SpeechSuperClient(
                http_client,
                app_key="app-key",
                secret_key="secret-key",
                base_url="https://speech.test",
            )
            result = await client.assess_word(
                _validated_audio(),
                reference_text="рыба",
                user_id=42,
            )

        self.assertEqual(result.score, 81)
        self.assertEqual(result.phoneme_scores, {"Р": 55, "Ы": 88})

    async def test_uses_sentence_core_type_for_phrase(self) -> None:
        async def handler(request: httpx.Request) -> httpx.Response:
            self.assertEqual(
                str(request.url),
                "https://speech.test/sent.eval.ru",
            )

            body = await request.aread()
            self.assertIn(b'"coreType":"sent.eval.ru"', body)
            self.assertIn("мама мыла раму".encode(), body)

            return httpx.Response(
                200,
                json={
                    "result": {
                        "overall": 90,
                        "words": [
                            {
                                "phonemes": [
                                    {"phoneme": "a", "pronunciation": 90},
                                ]
                            }
                        ],
                    }
                },
            )

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport) as http_client:
            client = SpeechSuperClient(
                http_client,
                app_key="app-key",
                secret_key="secret-key",
                base_url="https://speech.test",
            )
            result = await client.assess_word(
                _validated_audio(),
                reference_text="мама мыла раму",
                user_id=42,
            )

        self.assertEqual(result.score, 90)
        self.assertEqual(result.phoneme_scores, {"А": 90})

    async def test_maps_timeout_to_unavailable_error(self) -> None:
        async def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ReadTimeout("timeout", request=request)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport) as http_client:
            client = SpeechSuperClient(
                http_client,
                app_key="app-key",
                secret_key="secret-key",
            )

            with self.assertRaises(SpeechSuperUnavailableError):
                await client.assess_word(
                    _validated_audio(),
                    reference_text="рыба",
                    user_id=42,
                )


def _validated_audio() -> ValidatedAudio:
    """Создаёт уже проверенное аудио для теста клиента."""

    return ValidatedAudio(
        data=b"RIFF-test-audio",
        duration_seconds=1.0,
        sample_rate=16_000,
        channels=1,
        sample_width=2,
    )
