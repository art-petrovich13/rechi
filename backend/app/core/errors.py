"""Ошибки API с машиночитаемым кодом."""

from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse


class ApiError(HTTPException):
    """HTTP-ошибка, по коду которой клиент выбирает текст и действие."""

    def __init__(self, status_code: int, detail: str, code: str) -> None:
        super().__init__(status_code=status_code, detail=detail)
        self.code = code


async def api_error_handler(_: Request, error: ApiError) -> JSONResponse:
    """Отдаёт ошибку в формате {detail, code}."""

    return JSONResponse(
        status_code=error.status_code,
        content={"detail": error.detail, "code": error.code},
        headers=error.headers,
    )
