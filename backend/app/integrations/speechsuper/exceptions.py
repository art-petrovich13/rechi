"""Ошибки интеграции SpeechSuper."""


class SpeechSuperError(RuntimeError):
    """Базовая ошибка интеграции SpeechSuper."""


class SpeechSuperConfigurationError(SpeechSuperError):
    """Не заданы обязательные настройки SpeechSuper."""


class SpeechSuperUnavailableError(SpeechSuperError):
    """SpeechSuper не ответил или вернул HTTP-ошибку."""


class SpeechSuperResponseError(SpeechSuperError):
    """SpeechSuper вернул ответ неожиданного формата."""


class SpeechSuperAudioRejectedError(SpeechSuperError):
    """SpeechSuper не смог корректно обработать аудио."""
