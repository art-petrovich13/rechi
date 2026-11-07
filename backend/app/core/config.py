"""Настройки backend-приложения."""

import hashlib
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Настройки, загружаемые из переменных окружения и файла .env."""

    app_name: str = "Rechi API"
    app_version: str = "0.1.0"
    debug: bool = False
    log_level: str = "INFO"
    docs_enabled: bool = False
    database_url: str = (
        "postgresql+asyncpg://postgres:postgres@localhost:5432/rechi"
    )
    bot_token: str = ""
    public_url: str = ""
    telegram_webhook_secret: str = ""
    jwt_secret: str = ""
    jwt_algorithm: str = "HS256"
    jwt_expire_days: int = 30
    telegram_init_data_max_age_seconds: int = 86_400
    speech_super_key: str = ""
    speech_super_secret: str = ""
    speech_super_url: str = "https://api.speechsuper.com"
    speech_super_timeout_seconds: float = 30.0

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @property
    def telegram_webhook_url(self) -> str:
        """Возвращает публичный URL endpoint Telegram webhook."""

        return f"{self.public_url.rstrip('/')}/bot/webhook"

    @property
    def webhook_secret(self) -> str:
        """Возвращает секрет webhook; без настройки выводит его из токена бота."""

        if self.telegram_webhook_secret:
            return self.telegram_webhook_secret
        return hashlib.sha256(f"rechi-webhook:{self.bot_token}".encode()).hexdigest()


def validate_settings(config: Settings) -> None:
    """Останавливает запуск, если без настройки не сможет работать вход."""

    missing = [
        name
        for name, value in (
            ("BOT_TOKEN", config.bot_token),
            ("JWT_SECRET", config.jwt_secret),
        )
        if not value
    ]
    if missing:
        raise RuntimeError(f"Required settings are missing: {', '.join(missing)}")


@lru_cache
def get_settings() -> Settings:
    """Возвращает единственный экземпляр настроек приложения."""

    return Settings()


settings = get_settings()
