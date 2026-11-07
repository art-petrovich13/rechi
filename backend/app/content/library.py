"""Загрузка упражнений из файла данных.

Транскрипция, категория и сложность вычисляются, а не набиваются руками:
так они согласованы между собой и с подбором по звукам.
"""

import json
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from app.phonetics.transcription import (
    VOWEL_LETTERS,
    plain_text,
    stress_problems,
    transcribe,
)


CONTENT_PATH = Path(__file__).with_name("exercises.json")
AUDIENCES = ("all", "child", "adult")
# Звуки, которые осваиваются позже остальных и чаще нарушаются.
LATE_SOUNDS = frozenset("РЛШЖЩЧЦ")


@dataclass(frozen=True, slots=True)
class ExerciseSpec:
    """Упражнение, готовое к записи в базу."""

    key: str
    text: str
    stressed_text: str
    category: str
    difficulty: int
    audience: str
    phonemes: tuple[str, ...]


class ContentError(ValueError):
    """Ошибка в файле контента."""


@lru_cache
def load_exercises(path: Path = CONTENT_PATH) -> tuple[ExerciseSpec, ...]:
    """Читает и проверяет все упражнения."""

    raw = json.loads(path.read_text(encoding="utf-8"))
    specs: list[ExerciseSpec] = []
    keys: set[str] = set()
    for audience in AUDIENCES:
        for item in raw.get(audience, []):
            spec = build_spec(item, audience)
            if spec.key in keys:
                raise ContentError(f"Duplicate exercise: {spec.key}")
            keys.add(spec.key)
            specs.append(spec)
    return tuple(specs)


def build_spec(item: str | dict[str, str], audience: str) -> ExerciseSpec:
    """Строит упражнение из строки или объекта с ключом."""

    stressed = item if isinstance(item, str) else item["text"]
    stressed = " ".join(stressed.lower().split())
    problems = stress_problems(stressed)
    if problems:
        raise ContentError(f"Stress is missing or wrong in «{stressed}»: {problems}")

    text = plain_text(stressed)
    key = text if isinstance(item, str) else item.get("key", text)
    category = category_for(text)
    phonemes = tuple(transcribe(stressed))
    return ExerciseSpec(
        key=key,
        text=text,
        stressed_text=stressed,
        category=category,
        difficulty=difficulty_for(stressed, category, phonemes),
        audience=audience,
        phonemes=phonemes,
    )


def category_for(text: str) -> str:
    """Категория по числу слов."""

    count = len(text.split())
    if count == 1:
        return "word"
    if count <= 3:
        return "phrase"
    if count <= 6:
        return "sentence"
    raise ContentError(f"Too many words for a sentence: «{text}»")


def difficulty_for(
    stressed: str,
    category: str,
    phonemes: tuple[str, ...],
) -> int:
    """Уровень 1–3: поздние звуки, длина и стечения согласных."""

    late = LATE_SOUNDS.intersection(phonemes)
    if category == "word":
        syllables = sum(1 for char in stressed if char in VOWEL_LETTERS)
        cluster = _has_consonant_cluster(plain_text(stressed))
        level = 1 + bool(late) + (len(late) >= 2 or syllables >= 3 or cluster)
        return min(level, 3)
    if category == "phrase":
        return 3 if len(late) >= 3 else 2
    words = len(stressed.split())
    return 3 if words >= 5 or len(late) >= 4 else 2


def _has_consonant_cluster(text: str) -> bool:
    """Есть ли подряд три согласные буквы или две в начале слова."""

    run = 0
    for index, char in enumerate(text):
        if char.isalpha() and char not in VOWEL_LETTERS and char not in "ьъ":
            run += 1
            if run >= 3 or (run == 2 and index == 1):
                return True
        else:
            run = 0
    return False
