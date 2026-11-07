"""Упрощённая фонетическая транскрипция русского текста.

Ударение в тексте упражнения отмечается знаком «+» перед ударной гласной:
«соб+ака». В односложных словах и в словах с «ё» знак не нужен.

Правила покрывают то, что нужно для подбора упражнений по звукам:
йотированные гласные, редукцию безударных гласных, оглушение и озвончение,
непроизносимые согласные и частые исключения. Это приближение, а не
словарная транскрипция: сверять с ответами SpeechSuper.
"""

from app.phonetics.alphabet import (
    VOICED_OBSTRUENTS,
    VOICED_TO_VOICELESS,
    VOICELESS_OBSTRUENTS,
    VOICELESS_TO_VOICED,
)


STRESS_MARK = "+"
VOWEL_LETTERS = frozenset("аоуыиэеёюя")
IOTATED_LETTERS = frozenset("еёюя")
SIGN_LETTERS = frozenset("ьъ")
HARD_SIBILANTS = frozenset("ЖШЦ")
SOFT_AFFRICATES = frozenset("ЧЩ")
# Однобуквенные предлоги произносятся слитно со следующим словом.
CLITICS = frozenset({"в", "с", "к"})

_STRESSED_VOWELS = {
    "а": "А",
    "о": "О",
    "у": "У",
    "ы": "Ы",
    "и": "И",
    "э": "Е",
    "е": "Е",
    "ё": "О",
    "ю": "У",
    "я": "А",
}
_CONSONANTS = {
    letter: letter.upper() for letter in "бвгджзйклмнпрстфхцчшщ"
}
_CLUSTER_REPLACEMENTS = (
    ("ться", "ца"),
    ("тся", "ца"),
    ("вств", "ств"),
    ("стн", "сн"),
    ("здн", "зн"),
    ("лнц", "нц"),
    ("рдц", "рц"),
    ("стл", "сл"),
    ("сч", "щ"),
    ("зч", "щ"),
    ("гк", "хк"),
)
_SHT_WORDS = frozenset({"что", "чтобы", "ничто"})
_OGO_EXCEPTIONS = frozenset({"много", "немного", "строго", "дорого", "убого"})
_G_AS_V_WORDS = frozenset({"сегодня", "сегодняшний"})


def plain_text(text: str) -> str:
    """Убирает разметку ударения для показа пользователю."""

    return text.replace(STRESS_MARK, "")


def transcribe(text: str) -> list[str]:
    """Возвращает уникальные звуки текста в порядке первого появления."""

    result: list[str] = []
    for word in _phonetic_words(text):
        for phoneme in _transcribe_word(word):
            if phoneme not in result:
                result.append(phoneme)
    return result


def stress_problems(text: str) -> list[str]:
    """Слова, где ударение не отмечено или отмечено неверно."""

    problems = []
    for word in text.lower().split():
        letters = word.strip(".,!?;:«»\"")
        vowel_count = sum(1 for char in letters if char in VOWEL_LETTERS)
        marks = letters.count(STRESS_MARK)
        has_yo = "ё" in letters
        if marks > 1 or (marks == 1 and has_yo):
            problems.append(word)
        elif marks == 1:
            index = letters.index(STRESS_MARK)
            if index + 1 >= len(letters) or letters[index + 1] not in VOWEL_LETTERS:
                problems.append(word)
        elif vowel_count > 1 and not has_yo:
            problems.append(word)
    return problems


def _phonetic_words(text: str) -> list[str]:
    """Делит текст на фонетические слова, приклеивая предлоги."""

    words = [
        "".join(
            char
            for char in raw.lower()
            if char.isalpha() or char == STRESS_MARK
        )
        for raw in text.split()
    ]
    merged: list[str] = []
    pending = ""
    for word in words:
        if not word:
            continue
        if word in CLITICS:
            pending += word
            continue
        merged.append(pending + word)
        pending = ""
    if pending:
        merged.append(pending)
    return merged


def _prepare(word: str) -> str:
    """Применяет орфографические исключения произношения."""

    plain = plain_text(word)
    if plain in _SHT_WORDS:
        word = word.replace("чт", "шт", 1)
    if plain in _G_AS_V_WORDS or (
        len(plain) > 3
        and plain.endswith(("ого", "его"))
        and plain not in _OGO_EXCEPTIONS
    ):
        index = word.rfind("г")
        word = word[:index] + "в" + word[index + 1 :]
    for source, target in _CLUSTER_REPLACEMENTS:
        word = word.replace(source, target)
    return word


def _transcribe_word(word: str) -> list[str]:
    """Транскрибирует одно фонетическое слово."""

    word = _prepare(word)
    vowel_count = sum(1 for char in word if char in VOWEL_LETTERS)
    has_mark = STRESS_MARK in word
    letters = [char for char in word if char != STRESS_MARK]
    stressed_positions = _stressed_positions(word, vowel_count, has_mark)

    sounds: list[str] = []
    previous = ""
    for index, letter in enumerate(letters):
        if letter in SIGN_LETTERS:
            previous = letter
            continue
        if letter in VOWEL_LETTERS:
            iotated = letter in IOTATED_LETTERS and (
                not previous
                or previous in VOWEL_LETTERS
                or previous in SIGN_LETTERS
            )
            after = sounds[-1] if sounds else ""
            if iotated or (letter == "и" and previous == "ь"):
                sounds.append("Й")
                after = "Й"
            sounds.append(
                _vowel(
                    letter,
                    stressed=index in stressed_positions,
                    after=after,
                    final=index == len(letters) - 1,
                )
            )
        elif letter in _CONSONANTS:
            consonant = _CONSONANTS[letter]
            if not sounds or sounds[-1] != consonant:
                sounds.append(consonant)
        previous = letter
    return _assimilate(sounds)


def _stressed_positions(
    word: str,
    vowel_count: int,
    has_mark: bool,
) -> set[int]:
    """Индексы ударных гласных среди букв без знака «+»."""

    positions: set[int] = set()
    index = 0
    mark_next = False
    for char in word:
        if char == STRESS_MARK:
            mark_next = True
            continue
        if char in VOWEL_LETTERS and (
            mark_next or char == "ё" or (vowel_count == 1 and not has_mark)
        ):
            positions.add(index)
        mark_next = False
        index += 1
    return positions


def _vowel(letter: str, *, stressed: bool, after: str, final: bool) -> str:
    """Гласный звук с учётом ударения и предыдущего согласного."""

    if letter == "и" and after in HARD_SIBILANTS:
        return "Ы"
    if stressed:
        return _STRESSED_VOWELS[letter]
    if letter == "а" and after in SOFT_AFFRICATES:
        return "И"
    if letter in "ао":
        return "А"
    if letter in "еэ":
        return "Ы" if after in HARD_SIBILANTS else "И"
    if letter == "я":
        return "А" if final else "И"
    if letter == "ё":
        return "О"
    if letter == "ю":
        return "У"
    return _STRESSED_VOWELS[letter]


def _assimilate(sounds: list[str]) -> list[str]:
    """Оглушает и озвончает шумные согласные справа налево."""

    result = list(sounds)
    for index in range(len(result) - 1, -1, -1):
        sound = result[index]
        following = result[index + 1] if index + 1 < len(result) else None
        if following is None:
            result[index] = VOICED_TO_VOICELESS.get(sound, sound)
        elif following in VOICELESS_OBSTRUENTS:
            result[index] = VOICED_TO_VOICELESS.get(sound, sound)
        elif following in VOICED_OBSTRUENTS and following != "В":
            result[index] = VOICELESS_TO_VOICED.get(sound, sound)
    return result
