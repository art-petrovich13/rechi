"""Формирование подписей запросов SpeechSuper."""

import hashlib
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class SpeechSuperSignatures:
    """Подписи этапов connect и start."""

    connect: str
    start: str


def create_signatures(
    app_key: str,
    secret_key: str,
    timestamp: str,
    user_id: str,
) -> SpeechSuperSignatures:
    """Создаёт SHA-1 подписи согласно протоколу SpeechSuper."""

    connect_value = f"{app_key}{timestamp}{secret_key}".encode()
    start_value = f"{app_key}{timestamp}{user_id}{secret_key}".encode()
    return SpeechSuperSignatures(
        connect=hashlib.sha1(connect_value).hexdigest(),
        start=hashlib.sha1(start_value).hexdigest(),
    )
