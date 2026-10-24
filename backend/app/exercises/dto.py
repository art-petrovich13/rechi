"""Доменные значения упражнений."""

from enum import Enum


class ExerciseCategory(str, Enum):
    """Категория упражнения."""

    WORD = "word"
    PHRASE = "phrase"
    SENTENCE = "sentence"
