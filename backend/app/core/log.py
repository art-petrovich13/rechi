"""Настройка логирования приложения."""

import logging


def configure_logging(level: str) -> None:
    """Включает логи приложения: uvicorn настраивает только свои логгеры."""

    logging.basicConfig(
        level=level.upper(),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    logging.getLogger("httpx").setLevel(logging.WARNING)
