"""Заполняет базу начальными упражнениями MVP."""

import asyncio

from sqlalchemy import select

from app.data.db import async_session_factory, engine
from app.data.models import Exercise


EXERCISES: tuple[dict[str, object], ...] = (
    # Слова: один звук-фокус, который чаще всего страдает.
    {"text": "рыба", "phonemes": ["Р", "Ы", "Б", "А"], "difficulty": 1, "category": "word"},
    {"text": "рак", "phonemes": ["Р", "А", "К"], "difficulty": 1, "category": "word"},
    {"text": "роза", "phonemes": ["Р", "О", "З", "А"], "difficulty": 1, "category": "word"},
    {"text": "рука", "phonemes": ["Р", "У", "К", "А"], "difficulty": 1, "category": "word"},
    {"text": "сок", "phonemes": ["С", "О", "К"], "difficulty": 1, "category": "word"},
    {"text": "сова", "phonemes": ["С", "А", "В"], "difficulty": 1, "category": "word"},
    {"text": "сумка", "phonemes": ["С", "У", "М", "К", "А"], "difficulty": 1, "category": "word"},
    {"text": "шапка", "phonemes": ["Ш", "А", "П", "К", "А"], "difficulty": 1, "category": "word"},
    {"text": "шар", "phonemes": ["Ш", "А", "Р"], "difficulty": 1, "category": "word"},
    {"text": "шуба", "phonemes": ["Ш", "У", "Б", "А"], "difficulty": 1, "category": "word"},
    {"text": "лампа", "phonemes": ["Л", "А", "М", "П", "А"], "difficulty": 1, "category": "word"},
    {"text": "лук", "phonemes": ["Л", "У", "К"], "difficulty": 1, "category": "word"},
    {"text": "лиса", "phonemes": ["Л", "И", "С", "А"], "difficulty": 1, "category": "word"},
    {"text": "лодка", "phonemes": ["Л", "О", "Д", "К", "А"], "difficulty": 1, "category": "word"},
    {"text": "дом", "phonemes": ["Д", "О", "М"], "difficulty": 1, "category": "word"},
    {"text": "кот", "phonemes": ["К", "О", "Т"], "difficulty": 1, "category": "word"},
    {"text": "сыр", "phonemes": ["С", "Ы", "Р"], "difficulty": 1, "category": "word"},
    {"text": "мяч", "phonemes": ["М", "А", "Ч"], "difficulty": 1, "category": "word"},
    {"text": "жук", "phonemes": ["Ж", "У", "К"], "difficulty": 2, "category": "word"},
    {"text": "ёж", "phonemes": ["Й", "О", "Ш"], "difficulty": 2, "category": "word"},
    {"text": "цирк", "phonemes": ["Ц", "Ы", "Р", "К"], "difficulty": 2, "category": "word"},
    {"text": "чай", "phonemes": ["Ч", "А", "Й"], "difficulty": 2, "category": "word"},
    {"text": "щука", "phonemes": ["Щ", "У", "К", "А"], "difficulty": 2, "category": "word"},
    {"text": "чашка", "phonemes": ["Ч", "А", "Ш", "К", "А"], "difficulty": 2, "category": "word"},
    {"text": "мышка", "phonemes": ["М", "Ы", "Ш", "К", "А"], "difficulty": 2, "category": "word"},
    {"text": "ложка", "phonemes": ["Л", "О", "Ш", "К", "А"], "difficulty": 2, "category": "word"},
    {"text": "ракета", "phonemes": ["Р", "А", "К", "Е", "Т", "А"], "difficulty": 3, "category": "word"},
    # Словосочетания: 2–3 слова.
    {"text": "мама мыла раму", "phonemes": ["М", "А", "Ы", "Л", "Р", "У"], "difficulty": 2, "category": "phrase"},
    {"text": "шуба и шапка", "phonemes": ["Ш", "У", "Б", "А", "И", "П", "К"], "difficulty": 2, "category": "phrase"},
    {"text": "рыба в воде", "phonemes": ["Р", "Ы", "Б", "А", "В", "О", "Д", "Е"], "difficulty": 2, "category": "phrase"},
    {"text": "красная машина", "phonemes": ["К", "Р", "А", "С", "Н", "Я", "М", "Ш", "И"], "difficulty": 2, "category": "phrase"},
    {"text": "большая рыба", "phonemes": ["Б", "О", "Л", "Ш", "А", "Я", "Р", "Ы"], "difficulty": 2, "category": "phrase"},
    {"text": "синяя чашка", "phonemes": ["С", "И", "Н", "Я", "Ч", "А", "Ш", "К"], "difficulty": 2, "category": "phrase"},
    {"text": "новая шапка", "phonemes": ["Н", "О", "В", "А", "Я", "Ш", "П", "К"], "difficulty": 2, "category": "phrase"},
    {"text": "мама дома", "phonemes": ["М", "А", "Д", "О"], "difficulty": 2, "category": "phrase"},
    {"text": "кот спит", "phonemes": ["К", "О", "Т", "С", "П", "И"], "difficulty": 2, "category": "phrase"},
    {"text": "собака лает", "phonemes": ["С", "О", "Б", "А", "К", "Л", "Е", "Т"], "difficulty": 2, "category": "phrase"},
    {"text": "я вижу кота", "phonemes": ["Я", "В", "И", "Ж", "У", "К", "О", "Т", "А"], "difficulty": 2, "category": "phrase"},
    {"text": "папа читает", "phonemes": ["П", "А", "Ч", "И", "Т", "Е"], "difficulty": 2, "category": "phrase"},
    {"text": "дети играют", "phonemes": ["Д", "Е", "Т", "И", "Г", "Р", "А", "Ю"], "difficulty": 2, "category": "phrase"},
    {"text": "тёплый чай", "phonemes": ["Т", "Ё", "П", "Л", "Ы", "Й", "Ч", "А"], "difficulty": 2, "category": "phrase"},
    {"text": "вкусный суп", "phonemes": ["В", "К", "У", "С", "Н", "Ы", "Й", "П"], "difficulty": 2, "category": "phrase"},
    # Короткие предложения: 4–6 слов.
    {"text": "я вижу большую рыбу", "phonemes": ["Я", "В", "И", "Ж", "У", "Б", "О", "Л", "Ш", "А", "Ю", "Р", "Ы"], "difficulty": 2, "category": "sentence"},
    {"text": "мама купила красную шапку", "phonemes": ["М", "А", "К", "У", "П", "И", "Л", "Р", "С", "Н", "Ю", "Ш"], "difficulty": 2, "category": "sentence"},
    {"text": "папа читает интересную книгу", "phonemes": ["П", "А", "Ч", "И", "Т", "Е", "Н", "Р", "С", "У", "Ю", "К", "Г"], "difficulty": 3, "category": "sentence"},
    {"text": "дети играют во дворе", "phonemes": ["Д", "Е", "Т", "И", "Г", "Р", "А", "Ю", "В", "О"], "difficulty": 2, "category": "sentence"},
    {"text": "мы идём в парк гулять", "phonemes": ["М", "Ы", "И", "Д", "Ё", "В", "П", "А", "Р", "К", "Г", "У", "Л", "Я"], "difficulty": 3, "category": "sentence"},
    {"text": "сегодня светит яркое солнце", "phonemes": ["С", "Е", "Г", "О", "Д", "Н", "Я", "В", "Т", "И", "Р", "К", "Л", "Ц"], "difficulty": 3, "category": "sentence"},
    {"text": "кошка спит на тёплом окне", "phonemes": ["К", "О", "Ш", "А", "С", "П", "И", "Т", "Н", "Ё", "М", "Е"], "difficulty": 2, "category": "sentence"},
    {"text": "бабушка испекла вкусный пирог", "phonemes": ["Б", "А", "Ш", "К", "И", "С", "П", "Е", "Л", "В", "У", "Н", "Ы", "Й", "Р", "Г"], "difficulty": 3, "category": "sentence"},
    {"text": "я люблю пить тёплый чай", "phonemes": ["Я", "Л", "Ю", "Б", "П", "И", "Т", "Ё", "Ы", "Й", "Ч", "А"], "difficulty": 3, "category": "sentence"},
    {"text": "маленький котёнок пьёт молоко", "phonemes": ["М", "А", "Л", "Е", "Н", "Ь", "К", "И", "Й", "О", "Т", "Ё", "П", "Ю", "Д"], "difficulty": 3, "category": "sentence"},
    {"text": "утром мы пьём чай с бутербродом", "phonemes": ["У", "Т", "Р", "О", "М", "Ы", "П", "Ь", "Ё", "Ч", "А", "Й", "С", "Б", "Д"], "difficulty": 3, "category": "sentence"},
    {"text": "вечером дети читают интересную книгу", "phonemes": ["В", "Е", "Ч", "Р", "О", "М", "Д", "Т", "И", "А", "Ю", "Н", "С", "У", "К", "Г"], "difficulty": 3, "category": "sentence"},
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
            exercise.category = data["category"]

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
