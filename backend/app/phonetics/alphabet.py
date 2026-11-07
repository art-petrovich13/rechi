"""Звуки приложения и их группы.

Мягкие и твёрдые согласные объединены, как в ответах SpeechSuper после
нормализации. Гласный [э] обозначается буквой «Е».
"""

from dataclasses import dataclass


VOWELS: frozenset[str] = frozenset("АОУЫИЕ")
CONSONANTS: frozenset[str] = frozenset("БВГДЖЗЙКЛМНПРСТФХЦЧШЩ")
PHONEMES: frozenset[str] = VOWELS | CONSONANTS

VOICED_TO_VOICELESS: dict[str, str] = {
    "Б": "П",
    "В": "Ф",
    "Г": "К",
    "Д": "Т",
    "Ж": "Ш",
    "З": "С",
}
VOICELESS_TO_VOICED: dict[str, str] = {
    voiceless: voiced for voiced, voiceless in VOICED_TO_VOICELESS.items()
}
# Шумные согласные участвуют в оглушении и озвончении.
VOICELESS_OBSTRUENTS: frozenset[str] = frozenset("ПФКТШСХЦЧЩ")
VOICED_OBSTRUENTS: frozenset[str] = frozenset(VOICED_TO_VOICELESS)


@dataclass(frozen=True, slots=True)
class SoundGroup:
    """Группа звуков, которые тренируют вместе."""

    key: str
    title: str
    phonemes: tuple[str, ...]


SOUND_GROUPS: tuple[SoundGroup, ...] = (
    SoundGroup("hissing", "Шипящие", ("Ш", "Ж", "Ч", "Щ")),
    SoundGroup("whistling", "Свистящие", ("С", "З", "Ц")),
    SoundGroup("sonorant", "Сонорные", ("Р", "Л", "М", "Н")),
    SoundGroup("velar", "Заднеязычные", ("К", "Г", "Х")),
    SoundGroup("vowels", "Гласные", ("А", "О", "У", "Ы", "И", "Е")),
)
SOUND_GROUPS_BY_KEY: dict[str, SoundGroup] = {
    group.key: group for group in SOUND_GROUPS
}

# Пары по звонкости: «шар — жар», «дом — том».
VOICING_PAIRS: dict[str, str] = {
    **VOICED_TO_VOICELESS,
    **VOICELESS_TO_VOICED,
}


def groups_of(phoneme: str) -> tuple[SoundGroup, ...]:
    """Возвращает группы, в которые входит звук."""

    return tuple(group for group in SOUND_GROUPS if phoneme in group.phonemes)


def related_phonemes(phoneme: str) -> frozenset[str]:
    """Звуки, которые стоит тренировать вместе со слабым: группа и пара."""

    related = {
        member for group in groups_of(phoneme) for member in group.phonemes
    }
    pair = VOICING_PAIRS.get(phoneme)
    if pair is not None:
        related.add(pair)
    related.discard(phoneme)
    return frozenset(related)


def focus_phonemes(focus: str) -> frozenset[str]:
    """Звуки фокуса: ключ группы или один звук."""

    group = SOUND_GROUPS_BY_KEY.get(focus.strip().lower())
    if group is not None:
        return frozenset(group.phonemes)
    return frozenset({focus.strip().upper()})
