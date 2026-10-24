"""Тесты валидации WAV от Mini App."""

import io
import unittest
import wave

from app.assessment.audio.exceptions import (
    AudioSizeError,
    InvalidAudioDurationError,
    InvalidWavError,
    UnsupportedAudioMediaTypeError,
)
from app.assessment.audio.validator import MAX_AUDIO_BYTES, validate_wav


def make_wav(
    *,
    duration_seconds: float = 1.0,
    sample_rate: int = 16_000,
    channels: int = 1,
    sample_width: int = 2,
) -> bytes:
    """Создаёт WAV с тишиной и заданными параметрами."""

    frame_count = int(duration_seconds * sample_rate)
    frame = b"\x00" * sample_width * channels
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wav_file:
        wav_file.setnchannels(channels)
        wav_file.setsampwidth(sample_width)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(frame * frame_count)
    return buffer.getvalue()


class ValidateWavTests(unittest.TestCase):
    """Проверяет аудиоконтракт Mini App."""

    def test_accepts_expected_wav(self) -> None:
        audio = make_wav()

        result = validate_wav(audio, "audio/wav")

        self.assertEqual(result.data, audio)
        self.assertEqual(result.duration_seconds, 1.0)
        self.assertEqual(result.sample_rate, 16_000)
        self.assertEqual(result.channels, 1)
        self.assertEqual(result.sample_width, 2)

    def test_rejects_wrong_content_type(self) -> None:
        with self.assertRaises(UnsupportedAudioMediaTypeError):
            validate_wav(make_wav(), "audio/webm")

    def test_rejects_file_over_size_limit(self) -> None:
        with self.assertRaises(AudioSizeError):
            validate_wav(b"0" * (MAX_AUDIO_BYTES + 1), "audio/wav")

    def test_rejects_invalid_wav(self) -> None:
        with self.assertRaises(InvalidWavError):
            validate_wav(b"0" * 44, "audio/wav")

    def test_rejects_stereo(self) -> None:
        with self.assertRaises(InvalidWavError):
            validate_wav(make_wav(channels=2), "audio/wav")

    def test_rejects_wrong_sample_rate(self) -> None:
        with self.assertRaises(InvalidWavError):
            validate_wav(make_wav(sample_rate=48_000), "audio/wav")

    def test_rejects_wrong_sample_width(self) -> None:
        with self.assertRaises(InvalidWavError):
            validate_wav(make_wav(sample_width=1), "audio/wav")

    def test_rejects_too_short_audio(self) -> None:
        with self.assertRaises(InvalidAudioDurationError):
            validate_wav(make_wav(duration_seconds=0.5), "audio/wav")

    def test_accepts_twenty_second_audio(self) -> None:
        audio = make_wav(duration_seconds=20.0)

        result = validate_wav(audio, "audio/wav")

        self.assertEqual(result.duration_seconds, 20.0)

    def test_rejects_too_long_audio(self) -> None:
        with self.assertRaises(AudioSizeError):
            validate_wav(make_wav(duration_seconds=20.1), "audio/wav")


if __name__ == "__main__":
    unittest.main()
