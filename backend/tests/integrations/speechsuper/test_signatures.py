"""Тесты подписей SpeechSuper."""

import hashlib
import unittest

from app.integrations.speechsuper.signatures import create_signatures


class SpeechSuperSignaturesTests(unittest.TestCase):
    """Проверяет строки для connect и start."""

    def test_creates_expected_signatures(self) -> None:
        signatures = create_signatures("app", "secret", "123", "42")

        self.assertEqual(
            signatures.connect,
            hashlib.sha1(b"app123secret").hexdigest(),
        )
        self.assertEqual(
            signatures.start,
            hashlib.sha1(b"app12342secret").hexdigest(),
        )
