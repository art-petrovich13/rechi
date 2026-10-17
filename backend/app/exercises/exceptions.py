"""Исключения домена упражнений."""


class ExerciseNotFoundError(LookupError):
    """В базе нет доступных упражнений."""
