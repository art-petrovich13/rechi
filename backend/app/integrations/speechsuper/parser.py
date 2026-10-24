"""Разбор и нормализация ответов SpeechSuper."""

from typing import Any

from app.integrations.speechsuper.dto import SpeechAssessment, WordAssessment
from app.integrations.speechsuper.exceptions import (
    SpeechSuperAudioRejectedError,
    SpeechSuperResponseError,
)


# SpeechSuper uses Latin letters for some Russian vowels (a, o, i, u, y).
# The app stores Russian phonemes, so map homoglyphs to Cyrillic.
_PHONEME_REPLACEMENTS = str.maketrans(
    {
        "A": "А",
        "O": "О",
        "E": "Е",
        "I": "И",
        "U": "У",
        "Y": "Ы",
        "J": "Й",
    }
)


def parse_assessment_response(
    payload: Any,
    reference_text: str | None = None,
) -> SpeechAssessment:
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

    overall_score = _parse_score(result.get("overall"))
    raw_words = result.get("words")
    if not isinstance(raw_words, list) or not raw_words:
        raise SpeechSuperResponseError("SpeechSuper response has no words")

    reference_words = (reference_text or "").split()
    words: list[WordAssessment] = []
    phoneme_scores: dict[str, int] = {}

    for index, word in enumerate(raw_words):
        if not isinstance(word, dict):
            raise SpeechSuperResponseError("Invalid word result")

        word_phonemes = _parse_word_phonemes(word)
        for name, score in word_phonemes.items():
            previous_score = phoneme_scores.get(name)
            phoneme_scores[name] = (
                score if previous_score is None else min(previous_score, score)
            )

        text = _word_text(word, reference_words, index)
        word_score = _word_score(word, overall_score)
        words.append(
            WordAssessment(
                text=text,
                score=word_score,
                phoneme_scores=word_phonemes,
            )
        )

    if not phoneme_scores:
        raise SpeechSuperResponseError("SpeechSuper response has empty phonemes")

    return SpeechAssessment(
        score=overall_score,
        phoneme_scores=phoneme_scores,
        words=tuple(words),
    )


def _parse_word_phonemes(word: dict[str, Any]) -> dict[str, int]:
    """Собирает уникальные звуки одного слова."""

    phonemes = word.get("phonemes")
    if not isinstance(phonemes, list) or not phonemes:
        raise SpeechSuperResponseError("SpeechSuper response has no phonemes")

    scores: dict[str, int] = {}
    for phoneme in phonemes:
        if not isinstance(phoneme, dict):
            raise SpeechSuperResponseError("Invalid phoneme result")

        name = _normalize_phoneme(phoneme.get("phoneme"))
        phoneme_score = _parse_score(phoneme.get("pronunciation"))
        previous_score = scores.get(name)
        scores[name] = (
            phoneme_score if previous_score is None else min(previous_score, phoneme_score)
        )
    return scores


def _word_text(
    word: dict[str, Any],
    reference_words: list[str],
    index: int,
) -> str:
    """Возвращает текст слова из ответа или из reference text."""

    value = word.get("word")
    if isinstance(value, str) and value.strip():
        return value.strip()
    if index < len(reference_words):
        return reference_words[index]
    return ""


def _word_score(word: dict[str, Any], fallback: int) -> int:
    """Берёт overall/pronunciation слова, иначе общий балл."""

    scores = word.get("scores")
    if isinstance(scores, dict):
        for key in ("overall", "pronunciation"):
            if key in scores:
                return _parse_score(scores[key])
    return fallback


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
    normalized = normalized.translate(_PHONEME_REPLACEMENTS)
    if not normalized:
        raise SpeechSuperResponseError("Invalid phoneme")

    return normalized
