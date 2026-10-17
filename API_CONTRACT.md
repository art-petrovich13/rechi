# API Contract — Rechi MVP

**Статус:** черновик, зафиксирован по общему плану MVP от 17.10.2026.
**Владельцы:** Андрей (backend), Артём (mini_app).
**Правило:** после согласования файл read-only. Любое изменение полей, путей
или форматов — только через PR с одобрением обоих разработчиков.

---

## Base URL

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

JWT выдаётся `POST /api/auth/telegram` после проверки подписи `initData`.

---

## 1. POST `/api/auth/telegram`

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

## 2. GET `/api/exercises/next`

**Headers:** `Authorization: Bearer <token>`

**Response 200:**

```json
{
  "id": 5,
  "text": "рыба",
  "phonemes": ["Р", "Ы", "Б", "А"],
  "difficulty": 2
}
```

Правила:

- `id` — целое, уникальное;
- `text` — слово или короткая фраза на русском;
- `phonemes` — массив заглавных русских букв в порядке произношения;
- `difficulty` — целое 1–3;
- сервер не повторяет последнее выданное пользователю упражнение подряд,
  если в базе больше одного упражнения.

**Response 401:** невалидный/просроченный токен.
**Response 404:** упражнения закончились (клиент показывает «На сегодня всё»).

---

## 3. POST `/api/assess`

**Headers:** `Authorization: Bearer <token>`

**Body** — `multipart/form-data`:

| Поле | Тип | Обязательность | Описание |
|---|---|---|---|
| `audio` | file | да | запись пользователя |
| `exercise_id` | integer | да | id упражнения |

**Форматы аудио:**

- основной: `audio/wav` (PCM16, 16 кГц, моно) — так пишет Mini App;
- допустимые альтернативы: `audio/webm`, `audio/ogg` (старые клиенты и бот).

**Response 200:**

```json
{
  "score": 78,
  "phoneme_scores": { "Р": 45, "Ы": 88, "Б": 90, "А": 95 },
  "problematic": ["Р"]
}
```

Правила:

- `score` — целое 0–100;
- `phoneme_scores` — объект «заглавная буква → целое 0–100»; ключи должны
  совпадать с `phonemes` упражнения;
- если в слове звук повторяется (например, «шапка» → `Ш, А, П, К, А`),
  `phoneme_scores` содержит **уникальные** звуки: один балл на звук,
  а не на позицию;
- `problematic` — подмножество ключей с оценкой ниже порога (рекомендуется < 60),
  отсортировано по возрастанию оценки;
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

## 4. GET `/api/progress`

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
- `weak_phonemes` — до 5 звуков с наименьшим средним баллом, только по тем
  звукам, где есть хотя бы одна попытка;
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
| `Exercise { id, text, phonemes, difficulty }` | `Exercise` |
| `Assessment { score, phoneme_scores, problematic }` | `Assessment { score, phonemeScores, problematic }` |
| `Progress { attempts_count, weak_phonemes }` | `Progress { attemptsCount, weakPhonemes }` |
| `WeakPhoneme { phoneme, avg_score }` | `WeakPhoneme { phoneme, avgScore }` |

## Известные ограничения MVP

- `GET /api/exercises` (список) не нужен: клиент берёт только `next`.
- Аудио не хранится; повторное прослушивание на клиенте — локальное.
- Нет refresh-токена: JWT живёт достаточно долго для одной сессии Mini App.
- Нет эндпоинта удаления прогресса.

---

## Клиентские допущения

- В проде Mini App и backend должны быть на одном HTTPS-домене.
  Если домены разные — backend обязан отдавать CORS-заголовки для origin
  Mini App, включая `Authorization`.
- Клиент таймаутит `POST /api/assess` через 45 секунд, остальные запросы —
  через 20 секунд. GET-запросы один раз повторяются при сетевой ошибке/5xx.
- Клиент отправляет WAV (`audio/wav`, PCM16, 16 кГц, моно) в поле `audio`;
  старые клиенты могут присылать webm/ogg.
- Клиент не хранит JWT и аудио на диске. Флаг онбординга хранится
  в `localStorage` (`shared_preferences`).
- Цвета на клиенте: `score > 75` — зелёный, `50–75` — жёлтый, `< 50` — красный.
  Цвет не единственный носитель информации: рядом всегда стоит число.
- Если `initData` пустой: в debug клиент открывает демо-режим, в release —
  экран «Откройте через Telegram».
