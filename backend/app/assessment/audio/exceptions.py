"""Ошибки проверки входящего аудио."""


class AudioValidationError(ValueError):
    """Входящий аудиофайл не соответствует контракту."""

    code = "audio_invalid"


class UnsupportedAudioMediaTypeError(AudioValidationError):
    """Передан неподдерживаемый MIME-тип."""

    code = "audio_format"


class AudioSizeError(AudioValidationError):
    """Размер аудиофайла находится вне допустимых границ."""

    code = "audio_size"


class InvalidWavError(AudioValidationError):
    """Файл повреждён или имеет неподдерживаемые WAV-параметры."""


class InvalidAudioDurationError(AudioValidationError):
    """Продолжительность записи находится вне допустимых границ."""


class AudioTooShortError(InvalidAudioDurationError):
    """Запись короче минимума."""

    code = "audio_too_short"


class AudioTooLongError(InvalidAudioDurationError):
    """Запись длиннее максимума."""

    code = "audio_too_long"
