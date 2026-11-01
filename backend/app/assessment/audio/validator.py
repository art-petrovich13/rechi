"""Валидация и нормализация WAV-аудио от Mini App."""

import audioop
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
# iPhone/Safari may send 48 kHz stereo WAV. Accept up to ~8 MB and
# normalise to the SpeechSuper contract instead of rejecting the user.
MAX_AUDIO_BYTES = 8_000_000


def validate_wav(audio_bytes: bytes, content_type: str | None) -> ValidatedAudio:
    """Проверяет WAV и нормализует его в PCM16/16kHz/mono."""

    if content_type != EXPECTED_CONTENT_TYPE:
        raise UnsupportedAudioMediaTypeError("Audio must have audio/wav content type")

    if not MIN_WAV_HEADER_BYTES <= len(audio_bytes) <= MAX_AUDIO_BYTES:
        raise AudioSizeError("Audio size is outside allowed limits")

    try:
        with wave.open(io.BytesIO(audio_bytes), "rb") as wav_file:
            _validate_wav_format(wav_file)
            channel_count = wav_file.getnchannels()
            sample_width = wav_file.getsampwidth()
            sample_rate = wav_file.getframerate()
            frame_count = wav_file.getnframes()
            frame_data = wav_file.readframes(frame_count)
    except (EOFError, wave.Error) as error:
        raise InvalidWavError("Invalid WAV file") from error

    expected_frame_bytes = frame_count * channel_count * sample_width
    if len(frame_data) != expected_frame_bytes:
        raise InvalidWavError("WAV audio data is truncated")

    duration_seconds = frame_count / sample_rate
    if not MIN_DURATION_SECONDS <= duration_seconds <= MAX_DURATION_SECONDS:
        raise InvalidAudioDurationError(
            "Audio duration must be between 0.6 and 20 seconds"
        )

    normalized = _normalize_to_mono_16k(
        frame_data,
        channels=channel_count,
        sample_rate=sample_rate,
    )
    if not normalized:
        raise InvalidWavError("WAV audio data is empty")

    return ValidatedAudio(
        data=_wav_bytes(normalized),
        duration_seconds=duration_seconds,
        sample_rate=EXPECTED_SAMPLE_RATE,
        channels=EXPECTED_CHANNELS,
        sample_width=EXPECTED_SAMPLE_WIDTH,
    )


def _validate_wav_format(wav_file: wave.Wave_read) -> None:
    """Проверяет формат, который мы умеем нормализовать."""

    if wav_file.getcomptype() != "NONE":
        raise InvalidWavError("WAV must contain uncompressed PCM audio")
    if wav_file.getnchannels() not in (1, 2):
        raise InvalidWavError("WAV must be mono or stereo")
    if wav_file.getsampwidth() != EXPECTED_SAMPLE_WIDTH:
        raise InvalidWavError("WAV must use signed 16-bit samples")
    if wav_file.getframerate() <= 0:
        raise InvalidWavError("WAV sample rate must be positive")


def _normalize_to_mono_16k(
    frame_data: bytes,
    *,
    channels: int,
    sample_rate: int,
) -> bytes:
    """Приводит PCM16 к моно/16 кГц."""

    pcm = frame_data
    if channels == 2:
        pcm = audioop.tomono(pcm, 2, 0.5, 0.5)
    if sample_rate != EXPECTED_SAMPLE_RATE:
        pcm, _ = audioop.ratecv(
            pcm,
            2,
            1,
            sample_rate,
            EXPECTED_SAMPLE_RATE,
            None,
        )
    return pcm


def _wav_bytes(pcm: bytes) -> bytes:
    """Формирует WAV-контейнер PCM16/16kHz/mono."""

    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wav_file:
        wav_file.setnchannels(EXPECTED_CHANNELS)
        wav_file.setsampwidth(EXPECTED_SAMPLE_WIDTH)
        wav_file.setframerate(EXPECTED_SAMPLE_RATE)
        wav_file.writeframes(pcm)
    return buffer.getvalue()
