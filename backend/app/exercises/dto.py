"""Доменные значения упражнений."""

from enum import Enum


class ExerciseCategory(str, Enum):
    """Категория упражнения."""

    WORD = "word"
    PHRASE = "phrase"
    SENTENCE = "sentence"


class ExerciseAudience(str, Enum):
    """Для кого упражнение."""

    ALL = "all"
    CHILD = "child"
    ADULT = "adult"


class SelectionReason(str, Enum):
    """Почему подобрано упражнение: клиент показывает это пользователю."""

    REPEAT = "repeat"
    SIMILAR = "similar"
    NEW = "new"
    REVIEW = "review"
