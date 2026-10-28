# API Contract — Rechi MVP

**Статус:** черновик, зафиксирован по общему плану MVP от 17.10.2026.
**Владельцы:** Андрей (backend), Артём (mini_app).
**Правило:** после согласования файл read-only. Любое изменение полей, путей
или форматов — только через PR с одобрением обоих разработчиков.

---

## Base URL

**Версия API: `v1`** (backend реализует префикс `/api/v1`).

| Окружение | URL |
|---|---|
| Dev | `http://localhost:8000` |
| Prod | задаётся при сборке Mini App: `--dart-define=API_BASE_URL=https://<домен>` |

В клиенте адрес хранится только в `mini_app/lib/core/constants.dart`.

## Авторизация

Все защищённые эндпоинты принимают заголовок:

```
Authorization: Bearer <JWT>
```

JWT выдаётся `POST /api/v1/auth/telegram` после проверки подписи `initData`.

---

## 1. POST `/api/v1/auth/telegram`

Проверяет `initData` из `Telegram.WebApp.initData` и возвращает JWT.

**Request** — `application/json`:

```json
{
  "initData": "query_id=...&user=...&auth_date=...&hash=..."
}
```

**Response 200:**

```json
{
  "token": "jwt-строка",
  "user": {
    "id": 1,
    "first_name": "Иван"
  }
}
```

**Response 401:**

```json
{ "detail": "Invalid initData" }
```

Правила проверки (backend): `hash` через HMAC-SHA256 с ключом
`WebAppData` + `bot_token`, сравнение за постоянное время, проверка
`auth_date` (не старше 24 часов).

---

## 2. GET `/api/v1/exercises/next`

**Headers:** `Authorization: Bearer <token>`

**Query (необязательно):**

- `category=word|phrase|sentence` — категория;
- `focus=Р` — только упражнения, в которых есть этот звук;
- `exclude_id=5` — не возвращать текущее упражнение (кнопка «Другое»);
- без параметров — следующее непройденное упражнение.

Категории:

- `word` — одно слово;
- `phrase` — словосочетание из 2–3 слов;
- `sentence` — короткое предложение из 4–6 слов.

**Response 200:**

```json
{
  "id": 5,
  "text": "рыба",
  "phonemes": ["Р", "Ы", "Б", "А"],
  "difficulty": 2,
  "category": "word"
}
```

Правила:

- `id` — целое, уникальное;
- `text` — слово, словосочетание или короткое предложение (4–6 слов);
- `phonemes` — уникальные звуки в порядке первого появления; заглавные
  русские буквы; для фраз и предложений это объединение звуков всех слов;
- `difficulty` — целое 1–3;
- `category` — `word`, `phrase` или `sentence`;
- `focus` фильтрует по вхождению звука в `phonemes`; если упражнений нет —
  404;
- сервер отдаёт **первое непройденное** упражнение, сортировка:
  `difficulty` по возрастанию, затем `id`;
- пройденным считается упражнение, по которому есть хотя бы одна попытка
  пользователя;
- если все упражнения категории/фокуса пройдены — 404 (клиент показывает
  «На сегодня всё»);
- `exclude_id` нужен для «Другого»: пропуск не возвращает текущее слово.

**Response 422:** неизвестная категория (валидация FastAPI).
**Response 401:** невалидный/просроченный токен.
**Response 404:** упражнений в категории нет (клиент показывает пустое состояние).

---

## 3. POST `/api/v1/assess`

**Headers:** `Authorization: Bearer <token>`

**Body** — `multipart/form-data`:

| Поле | Тип | Обязательность | Описание |
|---|---|---|---|
| `audio` | file | да | запись пользователя |
| `exercise_id` | integer | да | id упражнения |

**Форматы аудио:**

- основной: `audio/wav` (PCM16, 16 кГц, моно) — так пишет Mini App;
- backend также принимает PCM16 44,1/48 кГц, моно или стерео и нормализует
  в 16 кГц/моно перед SpeechSuper (важно для iPhone/Safari);
- максимум 20 секунд и 8 МБ; для предложений 4–6 слов этого достаточно;
- допустимые альтернативы: `audio/webm`, `audio/ogg` (старые клиенты и бот).

**Response 200:**

```json
{
  "score": 78,
  "phoneme_scores": { "Р": 45, "Ы": 88, "Б": 90, "А": 95 },
  "problematic": ["Р"],
  "fluency": 74,
  "rhythm": 81,
  "pronunciation": 90,
  "speed": 186.0,
  "duration": 3.0,
  "words": [
    {
      "text": "мама",
      "score": 91,
      "phoneme_scores": { "М": 90, "А": 92 }
    },
    {
      "text": "мыла",
      "score": 84,
      "phoneme_scores": { "М": 88, "Ы": 80, "Л": 85, "А": 83 }
    }
  ]
}
```

Правила:

- `score` — целое 0–100;
- `phoneme_scores` — объект «заглавная буква → целое 0–100»; ключи должны
  совпадать с `phonemes` упражнения;
- если в слове звук повторяется (например, «шапка» → `Ш, А, П, К, А`),
  `phoneme_scores` содержит **уникальные** звуки: один балл на звук,
  а не на позицию;
- backend нормализует фонемы SpeechSuper в кириллицу: латинские `a/o/i/u/y`
  приходят как `А/О/И/У/Ы`, мягкий знак-апостроф отбрасывается;
- для фразы («мама мыла раму») backend сам выбирает `sent.eval.ru`, для
  одного слова — `word.eval.ru`; клиент об этом не думает;
- `problematic` — подмножество ключей с оценкой ниже порога (рекомендуется < 60),
  отсортировано по возрастанию оценки;
- `fluency`, `rhythm`, `pronunciation` — необязательные целые 0–100
  (приходят для фраз/предложений `sent.eval.ru`);
- `speed`, `duration` — необязательные числа; `duration` в секундах;
- `words` — разбор по словам в порядке произношения; для одного слова массив
  из одного элемента. У каждого слова:
  - `text` — слово из ответа SpeechSuper;
  - `score` — overall/pronunciation слова;
  - `phoneme_scores` — уникальные звуки слова с баллами;
- агрегированные `phoneme_scores` по-прежнему содержат минимум по всем словам;
- старые клиенты могут игнорировать `words`;
- аудио не сохраняется на диске и не пишется в БД;
- результат попытки сохраняется в `attempts` вместе с `phoneme_scores`.

**Response 400:** битый запрос / неподдерживаемый формат.
**Response 401:** невалидный токен.
**Response 404:** упражнение не найдено.
**Response 502:**

```json
{ "detail": "Speech service unavailable" }
```

**Response 504:** таймаут внешнего speech-сервиса.

---

## 4. GET `/api/v1/history`

**Headers:** `Authorization: Bearer <token>`

**Query:** `limit` — 1–50, по умолчанию 20.

Последние попытки пользователя, сначала новые.

**Response 200:**

```json
{
  "attempts": [
    {
      "id": 26,
      "exercise_id": 43,
      "exercise_text": "я вижу большую рыбу",
      "category": "sentence",
      "score": 100,
      "phoneme_scores": { "Я": 100, "В": 100 },
      "problematic": [],
      "words": [
        {
          "text": "я",
          "score": 100,
          "phoneme_scores": { "Й": 100, "А": 100 }
        }
      ],
      "created_at": "2026-10-24T20:14:00+00:00"
    }
  ]
}
```

Правила:

- `words` сохраняется в `attempts` и содержит разбор по словам;
- у старых попыток `words` может быть `[]`;
- `problematic` считается по агрегированным `phoneme_scores` (< 60);
- `limit` ограничен 1–50.

**Response 401:** невалидный токен.

---

## 5. GET `/api/v1/progress`

**Headers:** `Authorization: Bearer <token>`

**Response 200:**

```json
{
  "attempts_count": 42,
  "weak_phonemes": [
    { "phoneme": "Р", "avg_score": 52 },
    { "phoneme": "Ш", "avg_score": 61 }
  ]
}
```

Правила:

- `attempts_count` — общее число попыток пользователя;
- `weak_phonemes` — звуки со средним баллом ниже 70, отсортированы по
  возрастанию; учитываются только звуки, где есть хотя бы одна попытка;
  клиент показывает первые 5;
- `avg_score` — целое 0–100 (округление среднего);
- при отсутствии попыток: `{ "attempts_count": 0, "weak_phonemes": [] }`.

---

## Общие правила формата

- Все ключи JSON — `snake_case`.
- Все звуки — заглавные русские буквы: `"Р"`, `"Ш"`, `"Л"`.
- Ошибки — всегда `{ "detail": "<строка>" }`.
- Все ответы — `application/json; charset=utf-8`.
- Время — UTC ISO-8601, если поле появится.

## Соответствие Dart-моделей

| API | Dart |
|---|---|
| `AuthResponse { token, user }` | `AuthResponse` |
| `User { id, first_name }` | `User { id, firstName }` |
| `Exercise { id, text, phonemes, difficulty, category }` | `Exercise` |
| `Assessment { score, phoneme_scores, problematic, words, fluency, rhythm, pronunciation }` | `Assessment` |
| `HistoryResponse { attempts }` | `HistoryResponse` |
| `Progress { attempts_count, weak_phonemes }` | `Progress { attemptsCount, weakPhonemes }` |
| `WeakPhoneme { phoneme, avg_score }` | `WeakPhoneme { phoneme, avgScore }` |

## Известные ограничения MVP

- `GET /api/v1/exercises` (список) не нужен: клиент берёт только `next`.
- Аудио не хранится; повторное прослушивание на клиенте — локальное.
- Нет refresh-токена: JWT живёт достаточно долго для одной сессии Mini App.
- Нет эндпоинта удаления прогресса.

---

## Клиентские допущения

- В проде Mini App и backend должны быть на одном HTTPS-домене.
  Если домены разные — backend обязан отдавать CORS-заголовки для origin
  Mini App, включая `Authorization`.
- Клиент таймаутит `POST /api/v1/assess` через 45 секунд, остальные запросы —
  через 20 секунд. GET-запросы один раз повторяются при сетевой ошибке/5xx.
- Клиент отправляет WAV (`audio/wav`, PCM16, 16 кГц, моно) в поле `audio`; backend нормализует мобильные варианты 44,1/48 кГц и стерео;
  старые клиенты могут присылать webm/ogg.
- Клиент не хранит JWT и аудио на диске. Флаг онбординга хранится
  в `localStorage` (`shared_preferences`).
- Цвета на клиенте: `score > 75` — зелёный, `50–75` — жёлтый, `< 50` — красный.
  Цвет не единственный носитель информации: рядом всегда стоит число.
- Если `initData` пустой: в debug клиент открывает демо-режим, в release —
  экран «Откройте через Telegram».
