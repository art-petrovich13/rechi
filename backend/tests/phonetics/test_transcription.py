"""Тесты транскрипции и групп звуков."""

import unittest

from app.phonetics.alphabet import focus_phonemes, related_phonemes
from app.phonetics.transcription import stress_problems, transcribe


class TranscriptionTests(unittest.TestCase):
    """Сверяет транскрипцию с ответами SpeechSuper и правилами."""

    def test_reduces_unstressed_o(self) -> None:
        # Реальный SpeechSuper для «сова» вернул С, А, В.
        self.assertEqual(transcribe("сов+а"), ["С", "А", "В"])

    def test_iotated_vowel_at_word_start(self) -> None:
        self.assertEqual(transcribe("+яблоко")[:2], ["Й", "А"])
        self.assertEqual(transcribe("ёж"), ["Й", "О", "Ш"])

    def test_devoicing_and_voicing(self) -> None:
        self.assertIn("Т", transcribe("л+одка"))
        self.assertNotIn("Д", transcribe("л+одка"))
        self.assertEqual(transcribe("сд+елать")[0], "З")

    def test_silent_consonant(self) -> None:
        self.assertNotIn("Л", transcribe("с+олнце"))

    def test_preposition_joins_next_word(self) -> None:
        self.assertIn("З", transcribe("чай с бутербр+одом"))

    def test_exceptions(self) -> None:
        self.assertEqual(transcribe("что"), ["Ш", "Т", "О"])
        self.assertIn("В", transcribe("сег+одня"))
        self.assertIn("Ц", transcribe("уч+иться"))

    def test_hard_sibilant_makes_y(self) -> None:
        self.assertEqual(transcribe("жир+аф")[:2], ["Ж", "Ы"])

    def test_reports_missing_stress(self) -> None:
        self.assertEqual(stress_problems("р+ыба соба+ка кошка ёж кот"), ["соба+ка", "кошка"])


class SoundGroupTests(unittest.TestCase):
    """Проверяет подбор похожих звуков."""

    def test_related_includes_group_and_voicing_pair(self) -> None:
        related = related_phonemes("Ш")
        self.assertIn("Ж", related)
        self.assertIn("Щ", related)
        self.assertNotIn("Ш", related)

    def test_focus_accepts_group_key(self) -> None:
        self.assertEqual(focus_phonemes("whistling"), frozenset({"С", "З", "Ц"}))
        self.assertEqual(focus_phonemes("р"), frozenset({"Р"}))
