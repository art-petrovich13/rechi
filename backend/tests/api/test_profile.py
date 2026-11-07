"""Тесты профиля пользователя."""

import unittest
from unittest.mock import AsyncMock, MagicMock, patch

from fastapi.testclient import TestClient

from app.api.dependencies.auth import get_current_user
from app.api.dependencies.db import get_db
from app.data.models import User
from app.main import app


class ProfileTests(unittest.TestCase):
    """Аудитория, согласие и удаление данных."""

    def setUp(self) -> None:
        patcher = patch("app.main.validate_settings", MagicMock())
        patcher.start()
        self.addCleanup(patcher.stop)
        self.user = User(id=3, telegram_id=123, first_name="Аня")
        self.db = MagicMock()
        self.db.commit = AsyncMock()
        self.db.delete = AsyncMock()

        async def override_db():
            yield self.db

        async def override_user() -> User:
            return self.user

        app.dependency_overrides[get_db] = override_db
        app.dependency_overrides[get_current_user] = override_user
        self.addCleanup(app.dependency_overrides.clear)

    def test_new_user_has_no_audience_or_consent(self) -> None:
        with TestClient(app) as client:
            response = client.get("/api/v1/me")

        self.assertEqual(
            response.json(),
            {"id": 3, "first_name": "Аня", "audience": None, "consent_version": None},
        )

    def test_saves_audience_and_consent(self) -> None:
        with TestClient(app) as client:
            response = client.patch(
                "/api/v1/me", json={"audience": "child", "consent_version": 1}
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.user.audience, "child")
        self.assertEqual(self.user.consent_version, 1)
        self.assertIsNotNone(self.user.consented_at)
        self.db.commit.assert_awaited_once()

    def test_rejects_unknown_audience(self) -> None:
        with TestClient(app) as client:
            response = client.patch("/api/v1/me", json={"audience": "pets"})

        self.assertEqual(response.status_code, 422)

    def test_deletes_user(self) -> None:
        with TestClient(app) as client:
            response = client.delete("/api/v1/me")

        self.assertEqual(response.status_code, 204)
        self.db.delete.assert_awaited_once_with(self.user)
