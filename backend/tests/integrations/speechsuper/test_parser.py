"""Тесты разбора SpeechSuper-ответов."""

import unittest

from app.integrations.speechsuper.exceptions import (
    SpeechSuperAudioRejectedError,
    SpeechSuperResponseError,
)
from app.integrations.speechsuper.parser import parse_assessment_response


class SpeechSuperParserTests(unittest.TestCase):
    """Проверяет нормализацию результата оценки."""

    def test_parses_scores_and_merges_phonemes_by_minimum(self) -> None:
        payload = {
            "result": {
                "overall": 78.4,
                "words": [
                    {
                        "phonemes": [
                            {"phoneme": "р", "pronunciation": 60},
                            {"phoneme": "а", "pronunciation": 90},
                            {"phoneme": "р'", "pronunciation": 40},
                        ]
                    }
                ],
            }
        }

        result = parse_assessment_response(payload)

        self.assertEqual(result.score, 78)
        self.assertEqual(result.phoneme_scores, {"Р": 40, "А": 90})

    def test_parses_word_scores_and_phonemes(self) -> None:
        payload = {
            "result": {
                "overall": 72,
                "words": [
                    {
                        "word": "мама",
                        "scores": {"overall": 80, "pronunciation": 81},
                        "phonemes": [
                            {"phoneme": "м", "pronunciation": 90},
                            {"phoneme": "a", "pronunciation": 70},
                            {"phoneme": "м", "pronunciation": 85},
                        ],
                    },
                    {
                        "word": "мыла",
                        "scores": {"pronunciation": 64},
                        "phonemes": [
                            {"phoneme": "м", "pronunciation": 60},
                            {"phoneme": "ы", "pronunciation": 80},
                        ],
                    },
                ],
            }
        }

        result = parse_assessment_response(payload, "мама мыла")

        self.assertEqual(result.score, 72)
        self.assertEqual(result.words[0].text, "мама")
        self.assertEqual(result.words[0].score, 80)
        self.assertEqual(result.words[0].phoneme_scores, {"М": 85, "А": 70})
        self.assertEqual(result.words[1].text, "мыла")
        self.assertEqual(result.words[1].score, 64)
        self.assertEqual(
            result.phoneme_scores,
            {"М": 60, "А": 70, "Ы": 80},
        )

    def test_normalizes_latin_vowels_to_cyrillic(self) -> None:
        payload = {
            "result": {
                "overall": 80,
                "words": [
                    {
                        "phonemes": [
                            {"phoneme": "a", "pronunciation": 90},
                            {"phoneme": "o", "pronunciation": 80},
                            {"phoneme": "i", "pronunciation": 70},
                            {"phoneme": "u", "pronunciation": 60},
                            {"phoneme": "y", "pronunciation": 50},
                        ]
                    }
                ],
            }
        }

        result = parse_assessment_response(payload)

        self.assertEqual(
            result.phoneme_scores,
            {"А": 90, "О": 80, "И": 70, "У": 60, "Ы": 50},
        )

    def test_parses_sentence_metrics(self) -> None:
        payload = {
            "result": {
                "overall": 82,
                "fluency": 74.6,
                "rhythm": 81.2,
                "pronunciation": 90,
                "speed": 3.4,
                "duration": 2.8,
                "words": [
                    {
                        "word": "я",
                        "scores": {"overall": 90},
                        "phonemes": [{"phoneme": "я", "pronunciation": 90}],
                    }
                ],
            }
        }

        result = parse_assessment_response(payload)

        self.assertEqual(result.fluency, 75)
        self.assertEqual(result.rhythm, 81)
        self.assertEqual(result.pronunciation, 90)
        self.assertEqual(result.speed, 3.4)
        self.assertEqual(result.duration, 2.8)

    def test_rejects_audio_warning(self) -> None:
        payload = {
            "result": {
                "overall": 0,
                "warning": [{"code": 1001, "message": "No valid audio detected!"}],
                "words": [],
            }
        }

        with self.assertRaisesRegex(
            SpeechSuperAudioRejectedError,
            "No valid audio detected",
        ):
            parse_assessment_response(payload)

    def test_rejects_malformed_response(self) -> None:
        with self.assertRaises(SpeechSuperResponseError):
            parse_assessment_response({"unexpected": True})

    def test_rejects_score_outside_scale(self) -> None:
        payload = {
            "result": {
                "overall": 101,
                "words": [{"phonemes": [{"phoneme": "р", "pronunciation": 80}]}],
            }
        }

        with self.assertRaises(SpeechSuperResponseError):
            parse_assessment_response(payload)
