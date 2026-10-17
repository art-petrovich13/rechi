"""Разбор и нормализация ответов SpeechSuper."""

from typing import Any

from app.integrations.speechsuper.dto import SpeechAssessment
from app.integrations.speechsuper.exceptions import (
    SpeechSuperAudioRejectedError,
    SpeechSuperResponseError,
)


def parse_assessment_response(payload: Any) -> SpeechAssessment:
    """Преобразует ответ SpeechSuper в результат нашего приложения."""

    if not isinstance(payload, dict):
        raise SpeechSuperResponseError("SpeechSuper response must be an object")

    result = payload.get("result")
    if not isinstance(result, dict):
        raise SpeechSuperResponseError("SpeechSuper response has no result")

    warnings = result.get("warning")
    if isinstance(warnings, list) and warnings:
        messages = [
            item.get("message", "Audio was rejected")
            for item in warnings
            if isinstance(item, dict)
        ]
        raise SpeechSuperAudioRejectedError("; ".join(messages) or "Audio was rejected")

    score = _parse_score(result.get("overall"))
    words = result.get("words")
    if not isinstance(words, list) or not words:
        raise SpeechSuperResponseError("SpeechSuper response has no words")

    phoneme_scores: dict[str, int] = {}
    for word in words:
        if not isinstance(word, dict):
            raise SpeechSuperResponseError("Invalid word result")

        phonemes = word.get("phonemes")
        if not isinstance(phonemes, list):
            raise SpeechSuperResponseError("SpeechSuper response has no phonemes")

        for phoneme in phonemes:
            if not isinstance(phoneme, dict):
                raise SpeechSuperResponseError("Invalid phoneme result")

            name = _normalize_phoneme(phoneme.get("phoneme"))
            phoneme_score = _parse_score(phoneme.get("pronunciation"))
            previous_score = phoneme_scores.get(name)
            phoneme_scores[name] = (
                phoneme_score
                if previous_score is None
                else min(previous_score, phoneme_score)
            )

    if not phoneme_scores:
        raise SpeechSuperResponseError("SpeechSuper response has empty phonemes")

    return SpeechAssessment(score=score, phoneme_scores=phoneme_scores)


def _parse_score(value: Any) -> int:
    """Преобразует оценку SpeechSuper в целое число от 0 до 100."""

    if isinstance(value, bool):
        raise SpeechSuperResponseError("Invalid score")

    try:
        score = round(float(value))
    except (TypeError, ValueError) as error:
        raise SpeechSuperResponseError("Invalid score") from error

    if not 0 <= score <= 100:
        raise SpeechSuperResponseError("Score is outside the 0-100 range")

    return score


def _normalize_phoneme(value: Any) -> str:
    """Объединяет мягкие и твёрдые варианты в одну русскую фонему."""

    if not isinstance(value, str):
        raise SpeechSuperResponseError("Invalid phoneme")

    normalized = value.strip().replace("'", "").replace("’", "").upper()
    if not normalized:
        raise SpeechSuperResponseError("Invalid phoneme")

    return normalized
