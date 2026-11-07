"""Проверки файла контента: ошибки здесь ломают подбор упражнений."""

import unittest
from collections import Counter

from app.content.library import load_exercises
from app.phonetics.alphabet import CONSONANTS, PHONEMES


MIN_WORDS_PER_CONSONANT = 10


class ContentLibraryTests(unittest.TestCase):
    """Валидирует упражнения из exercises.json."""

    def test_loads_without_errors(self) -> None:
        self.assertGreaterEqual(len(load_exercises()), 300)

    def test_uses_only_known_phonemes(self) -> None:
        for spec in load_exercises():
            unknown = set(spec.phonemes) - PHONEMES
            self.assertFalse(unknown, f"{spec.text}: {unknown}")

    def test_phonemes_are_unique(self) -> None:
        for spec in load_exercises():
            self.assertEqual(len(spec.phonemes), len(set(spec.phonemes)), spec.text)

    def test_keeps_legacy_exercises(self) -> None:
        keys = {spec.key for spec in load_exercises()}
        for text in ("рыба", "сова", "мама мыла раму", "весной птицы поют громко"):
            self.assertIn(text, keys)

    def test_every_consonant_has_enough_words(self) -> None:
        words = [spec for spec in load_exercises() if spec.category == "word"]
        coverage = Counter(
            phoneme for spec in words for phoneme in spec.phonemes
        )
        thin = {
            consonant: coverage[consonant]
            for consonant in CONSONANTS
            if coverage[consonant] < MIN_WORDS_PER_CONSONANT
        }
        self.assertFalse(thin, f"Мало слов на звуки: {thin}")

    def test_every_category_and_audience_is_filled(self) -> None:
        pairs = Counter((spec.category, spec.audience) for spec in load_exercises())
        for audience in ("all", "child", "adult"):
            for category in ("word", "phrase", "sentence"):
                self.assertGreater(pairs[(category, audience)], 0, (category, audience))
