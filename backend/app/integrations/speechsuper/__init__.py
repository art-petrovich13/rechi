"""Интеграция с SpeechSuper API."""

from app.integrations.speechsuper.client import SpeechSuperClient
from app.integrations.speechsuper.dto import SpeechAssessment

__all__ = ["SpeechAssessment", "SpeechSuperClient"]
