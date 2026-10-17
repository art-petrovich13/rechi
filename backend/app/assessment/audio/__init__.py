"""Проверка и подготовка аудио для оценки произношения."""

from app.assessment.audio.dto import ValidatedAudio
from app.assessment.audio.validator import validate_wav

__all__ = ["ValidatedAudio", "validate_wav"]
