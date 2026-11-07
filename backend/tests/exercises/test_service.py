"""Тесты подбора упражнений."""

import unittest
from datetime import UTC, datetime, timedelta
from unittest.mock import AsyncMock, MagicMock

from app.data.models import Exercise, User
from app.exercises.dto import SelectionReason
from app.exercises.exceptions import ExerciseNotFoundError
from app.exercises.service import ExerciseStats, choose_exercise, get_next_exercise


NOW = datetime(2026, 11, 7, tzinfo=UTC)


def exercise(exercise_id: int, phonemes: str, difficulty: int = 1) -> Exercise:
    return Exercise(
        id=exercise_id,
        key=str(exercise_id),
        text=str(exercise_id),
        phonemes=list(phonemes),
        difficulty=difficulty,
        category="word",
    )


def stats(score: int, minutes_ago: int = 60) -> ExerciseStats:
    return ExerciseStats(last_score=score, last_at=NOW - timedelta(minutes=minutes_ago))


class ChooseExerciseTests(unittest.TestCase):
    """Правила выбора без базы данных."""

    def test_new_user_gets_easiest_new_exercise(self) -> None:
        pool = [exercise(1, "РЫБА", 2), exercise(2, "СОК", 1)]

        choice = choose_exercise(
            pool, stats={}, recent_ids=[], weak_phonemes=[], attempts_count=0
        )

        self.assertEqual(choice.exercise.id, 2)
        self.assertEqual(choice.reason, SelectionReason.NEW)

    def test_failed_exercise_comes_back(self) -> None:
        pool = [exercise(1, "РЫБА"), exercise(2, "СОК")]

        choice = choose_exercise(
            pool,
            stats={1: stats(5)},
            recent_ids=[],
            weak_phonemes=[],
            attempts_count=2,
        )

        self.assertEqual(choice.exercise.id, 1)
        self.assertEqual(choice.reason, SelectionReason.REPEAT)

    def test_repeats_alternate_with_new_exercises(self) -> None:
        pool = [exercise(1, "РЫБА"), exercise(2, "СОК")]

        choice = choose_exercise(
            pool,
            stats={1: stats(5)},
            recent_ids=[],
            weak_phonemes=[],
            attempts_count=3,
        )

        self.assertEqual(choice.exercise.id, 2)

    def test_recent_exercise_is_not_given_again_right_away(self) -> None:
        pool = [exercise(1, "РЫБА"), exercise(2, "СОК")]

        choice = choose_exercise(
            pool,
            stats={1: stats(5, minutes_ago=1)},
            recent_ids=[1],
            weak_phonemes=[],
            attempts_count=2,
        )

        self.assertEqual(choice.exercise.id, 2)

    def test_prefers_new_exercise_with_weak_or_similar_sound(self) -> None:
        pool = [exercise(1, "СОК"), exercise(2, "ЖУК", 3), exercise(3, "МАК")]

        choice = choose_exercise(
            pool,
            stats={},
            recent_ids=[],
            weak_phonemes=["Ш"],
            attempts_count=1,
        )

        self.assertEqual(choice.exercise.id, 2)
        self.assertEqual(choice.reason, SelectionReason.SIMILAR)

    def test_never_runs_out_when_everything_is_done(self) -> None:
        pool = [exercise(1, "СОК"), exercise(2, "МАК")]

        choice = choose_exercise(
            pool,
            stats={1: stats(95, minutes_ago=10), 2: stats(90, minutes_ago=600)},
            recent_ids=[],
            weak_phonemes=[],
            attempts_count=2,
        )

        self.assertEqual(choice.exercise.id, 2)
        self.assertEqual(choice.reason, SelectionReason.REVIEW)


class GetNextExerciseTests(unittest.IsolatedAsyncioTestCase):
    """Фильтры, которые применяются до выбора."""

    async def test_raises_only_when_filters_leave_nothing(self) -> None:
        db = MagicMock()
        db.scalars = AsyncMock(return_value=[exercise(5, "РЫБА")])

        with self.assertRaises(ExerciseNotFoundError):
            await get_next_exercise(db, User(id=3, telegram_id=1), exclude_ids=[5])

    async def test_focus_on_group_filters_by_sounds(self) -> None:
        db = MagicMock()
        db.scalars = AsyncMock(return_value=[exercise(5, "РЫБА")])

        with self.assertRaises(ExerciseNotFoundError):
            await get_next_exercise(db, User(id=3, telegram_id=1), focus="hissing")
