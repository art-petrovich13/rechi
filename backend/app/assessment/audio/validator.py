"""Валидация WAV-аудио от Mini App."""

import io
import wave

from app.assessment.audio.dto import ValidatedAudio
from app.assessment.audio.exceptions import (
    AudioSizeError,
    InvalidAudioDurationError,
    InvalidWavError,
    UnsupportedAudioMediaTypeError,
)


EXPECTED_CONTENT_TYPE = "audio/wav"
EXPECTED_SAMPLE_RATE = 16_000
EXPECTED_CHANNELS = 1
EXPECTED_SAMPLE_WIDTH = 2
MIN_DURATION_SECONDS = 0.6
MAX_DURATION_SECONDS = 20.0
MIN_WAV_HEADER_BYTES = 44
MAX_AUDIO_BYTES = 640_044


def validate_wav(audio_bytes: bytes, content_type: str | None) -> ValidatedAudio:
    """Проверяет WAV PCM16/16kHz/mono и возвращает его параметры."""

    if content_type != EXPECTED_CONTENT_TYPE:
        raise UnsupportedAudioMediaTypeError("Audio must have audio/wav content type")

    if not MIN_WAV_HEADER_BYTES <= len(audio_bytes) <= MAX_AUDIO_BYTES:
        raise AudioSizeError("Audio size is outside allowed limits")

    try:
        with wave.open(io.BytesIO(audio_bytes), "rb") as wav_file:
            _validate_wav_params(wav_file)
            frame_count = wav_file.getnframes()
            duration_seconds = frame_count / EXPECTED_SAMPLE_RATE
            frame_data = wav_file.readframes(frame_count)
    except (EOFError, wave.Error) as error:
        raise InvalidWavError("Invalid WAV file") from error

    expected_frame_bytes = frame_count * EXPECTED_CHANNELS * EXPECTED_SAMPLE_WIDTH
    if len(frame_data) != expected_frame_bytes:
        raise InvalidWavError("WAV audio data is truncated")

    if not MIN_DURATION_SECONDS <= duration_seconds <= MAX_DURATION_SECONDS:
        raise InvalidAudioDurationError("Audio duration must be between 0.6 and 20 seconds")

    return ValidatedAudio(
        data=audio_bytes,
        duration_seconds=duration_seconds,
        sample_rate=EXPECTED_SAMPLE_RATE,
        channels=EXPECTED_CHANNELS,
        sample_width=EXPECTED_SAMPLE_WIDTH,
    )


def _validate_wav_params(wav_file: wave.Wave_read) -> None:
    """Проверяет параметры открытого WAV-файла."""

    if wav_file.getcomptype() != "NONE":
        raise InvalidWavError("WAV must contain uncompressed PCM audio")
    if wav_file.getnchannels() != EXPECTED_CHANNELS:
        raise InvalidWavError("WAV must be mono")
    if wav_file.getsampwidth() != EXPECTED_SAMPLE_WIDTH:
        raise InvalidWavError("WAV must use signed 16-bit samples")
    if wav_file.getframerate() != EXPECTED_SAMPLE_RATE:
        raise InvalidWavError("WAV sample rate must be 16000 Hz")
