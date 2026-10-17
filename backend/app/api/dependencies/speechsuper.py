"""Зависимости интеграции со SpeechSuper."""

from collections.abc import AsyncIterator

import httpx
from fastapi import HTTPException, status

from app.core.config import settings
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
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Speech service is not configured",
            ) from error
