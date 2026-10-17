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
    {"text": "сова", "phonemes": ["С", "О", "В", "А"], "difficulty": 1},
    {"text": "сумка", "phonemes": ["С", "У", "М", "К", "А"], "difficulty": 1},
    {"text": "шапка", "phonemes": ["Ш", "А", "П", "К", "А"], "difficulty": 1},
    {"text": "шар", "phonemes": ["Ш", "А", "Р"], "difficulty": 1},
    {"text": "шуба", "phonemes": ["Ш", "У", "Б", "А"], "difficulty": 1},
    {"text": "лампа", "phonemes": ["Л", "А", "М", "П", "А"], "difficulty": 1},
    {"text": "лук", "phonemes": ["Л", "У", "К"], "difficulty": 1},
    {"text": "лиса", "phonemes": ["Л", "И", "С", "А"], "difficulty": 1},
    {"text": "лодка", "phonemes": ["Л", "О", "Д", "К", "А"], "difficulty": 1},
)


async def seed_exercises() -> int:
    """Добавляет отсутствующие упражнения и возвращает их количество."""

    async with async_session_factory() as session:
        existing_texts = set(await session.scalars(select(Exercise.text)))
        new_exercises = [
            Exercise(**exercise)
            for exercise in EXERCISES
            if exercise["text"] not in existing_texts
        ]

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
