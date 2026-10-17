"""Ошибки проверки входящего аудио."""


class AudioValidationError(ValueError):
    """Входящий аудиофайл не соответствует контракту."""


class UnsupportedAudioMediaTypeError(AudioValidationError):
    """Передан неподдерживаемый MIME-тип."""


class AudioSizeError(AudioValidationError):
    """Размер аудиофайла находится вне допустимых границ."""


class InvalidWavError(AudioValidationError):
    """Файл повреждён или имеет неподдерживаемые WAV-параметры."""


class InvalidAudioDurationError(AudioValidationError):
    """Продолжительность записи находится вне допустимых границ."""
