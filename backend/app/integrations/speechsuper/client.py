"""Асинхронный HTTP-клиент SpeechSuper."""

import json
import time
from typing import Any
from uuid import uuid4

import httpx

from app.assessment.audio.dto import ValidatedAudio
from app.core.config import settings
from app.integrations.speechsuper.dto import SpeechAssessment
from app.integrations.speechsuper.exceptions import (
    SpeechSuperConfigurationError,
    SpeechSuperResponseError,
    SpeechSuperUnavailableError,
)
from app.integrations.speechsuper.parser import parse_assessment_response
from app.integrations.speechsuper.signatures import create_signatures


CORE_TYPE = "word.eval.ru"


class SpeechSuperClient:
    """Отправляет русское слово и WAV-аудио в SpeechSuper."""

    def __init__(
        self,
        http_client: httpx.AsyncClient,
        *,
        app_key: str,
        secret_key: str,
        base_url: str = "https://api.speechsuper.com",
    ) -> None:
        if not app_key or not secret_key:
            raise SpeechSuperConfigurationError("SpeechSuper credentials are missing")

        self._http_client = http_client
        self._app_key = app_key
        self._secret_key = secret_key
        self._url = f"{base_url.rstrip('/')}/{CORE_TYPE}"

    @classmethod
    def from_settings(cls, http_client: httpx.AsyncClient) -> "SpeechSuperClient":
        """Создаёт клиент из настроек приложения."""

        return cls(
            http_client,
            app_key=settings.speech_super_key,
            secret_key=settings.speech_super_secret,
            base_url=settings.speech_super_url,
        )

    async def assess_word(
        self,
        audio: ValidatedAudio,
        reference_text: str,
        user_id: int,
    ) -> SpeechAssessment:
        """Оценивает произношение одного русского слова."""

        request_payload = self._build_request_payload(audio, reference_text, user_id)
        try:
            response = await self._http_client.post(
                self._url,
                data={
                    "text": json.dumps(
                        request_payload,
                        ensure_ascii=False,
                        separators=(",", ":"),
                    )
                },
                files={
                    "audio": (
                        "recording.wav",
                        audio.data,
                        "application/octet-stream",
                    )
                },
                headers={"Request-Index": "0"},
            )
            response.raise_for_status()
        except (httpx.TimeoutException, httpx.HTTPStatusError, httpx.RequestError) as error:
            raise SpeechSuperUnavailableError("SpeechSuper request failed") from error

        try:
            payload: Any = response.json()
        except ValueError as error:
            raise SpeechSuperResponseError("SpeechSuper returned invalid JSON") from error

        return parse_assessment_response(payload)

    def _build_request_payload(
        self,
        audio: ValidatedAudio,
        reference_text: str,
        user_id: int,
    ) -> dict[str, Any]:
        """Формирует параметр text для multipart-запроса SpeechSuper."""

        timestamp = str(int(time.time()))
        external_user_id = str(user_id)
        signatures = create_signatures(
            self._app_key,
            self._secret_key,
            timestamp,
            external_user_id,
        )
        token_id = uuid4().hex

        return {
            "connect": {
                "cmd": "connect",
                "param": {
                    "sdk": {"version": 16_777_472, "source": 9, "protocol": 2},
                    "app": {
                        "applicationId": self._app_key,
                        "timestamp": timestamp,
                        "sig": signatures.connect,
                    },
                },
            },
            "start": {
                "cmd": "start",
                "param": {
                    "app": {
                        "userId": external_user_id,
                        "applicationId": self._app_key,
                        "timestamp": timestamp,
                        "sig": signatures.start,
                    },
                    "audio": {
                        "audioType": audio.audio_type,
                        "channel": audio.channels,
                        "sampleBytes": audio.sample_width,
                        "sampleRate": audio.sample_rate,
                    },
                    "request": {
                        "tokenId": token_id,
                        "coreType": CORE_TYPE,
                        "refText": reference_text,
                        "phoneme_output": 1,
                        "scale": 100,
                        "precision": 1,
                    },
                },
            },
        }
