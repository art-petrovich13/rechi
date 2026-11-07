"""Зависимости интеграции со SpeechSuper."""

from collections.abc import AsyncIterator

import httpx
from fastapi import status

from app.core.config import settings
from app.core.errors import ApiError
from app.integrations.speechsuper.client import SpeechSuperClient
from app.integrations.speechsuper.exceptions import SpeechSuperConfigurationError


async def get_speech_super_client() -> AsyncIterator[SpeechSuperClient]:
    """Создаёт HTTP-клиент SpeechSuper на время запроса."""

    async with httpx.AsyncClient(
        timeout=settings.speech_super_timeout_seconds,
    ) as http_client:
        try:
            yield SpeechSuperClient.from_settings(http_client)
        except SpeechSuperConfigurationError as error:
            raise ApiError(
                status.HTTP_502_BAD_GATEWAY,
                "Speech service is not configured",
                "speech_not_configured",
            ) from error
