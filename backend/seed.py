"""Синхронизирует упражнения в базе с файлом app/content/exercises.json."""

import asyncio

from sqlalchemy import select

from app.content.library import load_exercises
from app.data.db import async_session_factory, engine
from app.data.models import Exercise


async def seed_exercises() -> tuple[int, int, int]:
    """Добавляет, обновляет и скрывает упражнения. Возвращает счётчики."""

    specs = load_exercises()
    async with async_session_factory() as session:
        existing = {
            exercise.key: exercise
            for exercise in await session.scalars(select(Exercise))
        }
        created = 0
        for spec in specs:
            exercise = existing.pop(spec.key, None)
            if exercise is None:
                exercise = Exercise(key=spec.key)
                session.add(exercise)
                created += 1
            exercise.text = spec.text
            exercise.stressed_text = spec.stressed_text
            exercise.phonemes = list(spec.phonemes)
            exercise.difficulty = spec.difficulty
            exercise.category = spec.category
            exercise.audience = spec.audience
            exercise.is_active = True

        # Удалённые из файла упражнения скрываются, история попыток остаётся.
        hidden = 0
        for exercise in existing.values():
            if exercise.is_active:
                exercise.is_active = False
                hidden += 1

        await session.commit()
        return created, len(specs), hidden


async def main() -> None:
    """Запускает синхронизацию и освобождает подключения."""

    try:
        created, total, hidden = await seed_exercises()
        print(f"Упражнений в файле: {total}, добавлено: {created}, скрыто: {hidden}")
    finally:
        await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
