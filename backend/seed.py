"""Заполняет базу начальными упражнениями MVP."""

import asyncio

from sqlalchemy import select

from app.data.db import async_session_factory, engine
from app.data.models import Exercise


EXERCISES: tuple[dict[str, object], ...] = (
    {"text": "рыба", "phonemes": ["Р", "Ы", "Б", "А"], "difficulty": 1},
    {"text": "рак", "phonemes": ["Р", "А", "К"], "difficulty": 1},
    {"text": "роза", "phonemes": ["Р", "О", "З", "А"], "difficulty": 1},
    {"text": "рука", "phonemes": ["Р", "У", "К", "А"], "difficulty": 1},
    {"text": "сок", "phonemes": ["С", "О", "К"], "difficulty": 1},
    {"text": "сова", "phonemes": ["С", "А", "В"], "difficulty": 1},
    {"text": "сумка", "phonemes": ["С", "У", "М", "К", "А"], "difficulty": 1},
    {"text": "шапка", "phonemes": ["Ш", "А", "П", "К", "А"], "difficulty": 1},
    {"text": "шар", "phonemes": ["Ш", "А", "Р"], "difficulty": 1},
    {"text": "шуба", "phonemes": ["Ш", "У", "Б", "А"], "difficulty": 1},
    {"text": "лампа", "phonemes": ["Л", "А", "М", "П", "А"], "difficulty": 1},
    {"text": "лук", "phonemes": ["Л", "У", "К"], "difficulty": 1},
    {"text": "лиса", "phonemes": ["Л", "И", "С", "А"], "difficulty": 1},
    {"text": "лодка", "phonemes": ["Л", "О", "Д", "К", "А"], "difficulty": 1},
    {"text": "мама мыла раму", "phonemes": ["М", "А", "Ы", "Л", "Р", "У"], "difficulty": 2},
    {"text": "шуба и шапка", "phonemes": ["Ш", "У", "Б", "А", "И", "П", "К"], "difficulty": 2},
    {"text": "рыба в воде", "phonemes": ["Р", "Ы", "Б", "А", "В", "Д", "Е"], "difficulty": 2},
)


async def seed_exercises() -> int:
    """Добавляет отсутствующие упражнения и возвращает их количество."""

    async with async_session_factory() as session:
        existing = {
            exercise.text: exercise
            for exercise in await session.scalars(select(Exercise))
        }
        new_exercises: list[Exercise] = []
        for data in EXERCISES:
            exercise = existing.get(data["text"])
            if exercise is None:
                new_exercises.append(Exercise(**data))
                continue
            exercise.phonemes = data["phonemes"]
            exercise.difficulty = data["difficulty"]

        session.add_all(new_exercises)
        await session.commit()
        return len(new_exercises)


async def main() -> None:
    """Запускает наполнение базы и освобождает подключения."""

    try:
        created_count = await seed_exercises()
        print(f"Добавлено упражнений: {created_count}")
    finally:
        await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
