"""Тесты последовательности упражнений."""

import unittest
from unittest.mock import AsyncMock, MagicMock

from app.data.models import Exercise, User
from app.exercises.dto import ExerciseCategory
from app.exercises.exceptions import ExerciseNotFoundError
from app.exercises.service import get_next_exercise


class ExerciseServiceTests(unittest.IsolatedAsyncioTestCase):
    """Проверяет порядок и завершение тренировки."""

    async def test_selects_unattempted_by_difficulty(self) -> None:
        db = MagicMock()
        db.scalar = AsyncMock(
            return_value=Exercise(
                id=5,
                text="рыба",
                phonemes=["Р", "Ы", "Б", "А"],
                difficulty=1,
                category="word",
            )
        )

        exercise = await get_next_exercise(
            db,
            User(id=3, telegram_id=123),
            ExerciseCategory.WORD,
        )

        self.assertEqual(exercise.id, 5)
        statement = str(db.scalar.await_args.args[0])
        self.assertIn("NOT IN", statement)
        self.assertIn("ORDER BY exercises.difficulty, exercises.id", statement)

    async def test_excludes_current_exercise(self) -> None:
        db = MagicMock()
        db.scalar = AsyncMock(
            return_value=Exercise(
                id=6,
                text="сова",
                phonemes=["С", "А", "В"],
                difficulty=1,
                category="word",
            )
        )

        await get_next_exercise(
            db,
            User(id=3, telegram_id=123),
            ExerciseCategory.WORD,
            exclude_id=5,
        )

        statement = str(db.scalar.await_args.args[0])
        self.assertIn("exercises.id !=", statement)

    async def test_raises_when_everything_completed(self) -> None:
        db = MagicMock()
        db.scalar = AsyncMock(return_value=None)

        with self.assertRaises(ExerciseNotFoundError):
            await get_next_exercise(
                db,
                User(id=3, telegram_id=123),
                ExerciseCategory.WORD,
            )
