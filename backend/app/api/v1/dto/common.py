"""Общие типы и DTO API версии 1."""

from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field


Score = Annotated[int, Field(ge=0, le=100)]


class ApiSchema(BaseModel):
    """Базовый DTO с запретом неизвестных полей."""

    model_config = ConfigDict(extra="forbid", populate_by_name=True)


class ErrorResponse(ApiSchema):
    """Стандартный ответ API с описанием ошибки."""

    detail: str = Field(min_length=1)
