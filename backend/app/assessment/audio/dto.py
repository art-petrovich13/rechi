"""Внутренние структуры проверенного аудио."""

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class ValidatedAudio:
    """WAV-аудио, параметры которого проверены backend-приложением."""

    data: bytes
    duration_seconds: float
    sample_rate: int
    channels: int
    sample_width: int
    audio_type: str = "wav"
