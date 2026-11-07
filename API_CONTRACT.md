# API Contract — Rechi MVP

**Статус:** действующий контракт, обновляется вместе с кодом.
**Владелец:** Артём.

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
    "first_name": "Иван",
    "audience": null,
    "consent_version": null
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

## 1a. Профиль `/api/v1/me`

**Headers:** `Authorization: Bearer <token>`

| Метод | Тело | Ответ |
|---|---|---|
| `GET` | — | пользователь, как в `auth/telegram` |
| `PATCH` | `{ "audience": "child" \| "adult", "consent_version": 1 }`, любые поля | обновлённый пользователь |
| `DELETE` | — | 204; пользователь и все попытки удалены без восстановления |

Правила:

- `audience` — кто занимается; `null` — ещё не выбрано, клиент спрашивает при
  входе. Влияет на подбор (`/exercises/next` без `audience` берёт его из профиля)
  и на тон текстов клиента;
- `consent_version` — версия принятого текста согласия; клиент показывает
  согласие, если она ниже текущей (`consentVersion` в `constants.dart`);
- после `DELETE` старый токен даёт 401; следующий вход создаёт нового
  пользователя без истории.

---

## 2. GET `/api/v1/exercises/next`

**Headers:** `Authorization: Bearer <token>`

**Query (необязательно):**

- `category=word|phrase|sentence` — категория;
- `focus=Р` или `focus=hissing` — звук или группа звуков (`hissing` шипящие,
  `whistling` свистящие, `sonorant` сонорные, `velar` заднеязычные, `vowels`);
- `exclude_id=5&exclude_id=7` — не возвращать эти упражнения (кнопка «Другое»),
  параметр можно повторять, максимум 100 значений;
- `audience=child|adult` — кроме общих, добавить упражнения этой аудитории.

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
  "category": "word",
  "audience": "all",
  "reason": "repeat"
}
```

Правила:

- `phonemes` — уникальные звуки в порядке первого появления. Считаются
  транскрипцией по тексту с ударением, поэтому совпадают со словарём
  SpeechSuper: безударное «о» даёт `А`, «я» в начале слова — `Й, А`, мягкость
  не различается;
- `difficulty` — 1–3, считается по поздним звукам (Р Л Ш Ж Щ Ч Ц), длине и
  стечениям согласных;
- `reason` — почему выбрано упражнение:

| `reason` | Когда |
|---|---|
| `repeat` | последний балл ниже 70; повторы чередуются с новыми |
| `similar` | новое упражнение со слабыми звуками или похожими на них |
| `new` | новое упражнение по уровню |
| `review` | всё пройдено хорошо, давно не встречалось |

- упражнения последних 5 попыток откладываются, чтобы «Дальше» не давало то же;
- упражнения не заканчиваются: 404 только если фильтры не оставили ни одного;
- `exclude_id` нужен для «Другого»: клиент передаёт все пропущенные упражнения,
  а получив 404 при непустом списке, очищает его и идёт по кругу.

**Response 422:** неизвестная категория (валидация FastAPI).
**Response 401:** невалидный/просроченный токен.
**Response 404:** подходящих упражнений нет, код `no_exercises` (клиент показывает
пустое состояние).

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
- клиент ограничивает запись 20 секундами, сервер принимает до 21 секунды, чтобы
  не отклонять запись, упёршуюся в лимит; минимум 0,6 секунды, максимум 8 МБ;
- MIME строго `audio/wav`, другие форматы дают 400.

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
- `phoneme_scores` — объект «заглавная буква → целое 0–100»; ключи берутся из
  ответа SpeechSuper и в основном совпадают с `phonemes` упражнения;
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
- если звук встречается несколько раз, его балл — среднее по всем произнесениям,
  и в слове, и в агрегате по фразе;
- старые клиенты могут игнорировать `words`;
- аудио не сохраняется на диске и не пишется в БД;
- результат попытки сохраняется в `attempts` вместе с `phoneme_scores`.

**Ошибки** (`code` определяет текст на клиенте):

| Статус | `code` | Что значит | Действие клиента |
|---|---|---|---|
| 400 | `audio_format`, `audio_invalid`, `audio_size` | файл не подходит | новая запись |
| 400 | `audio_too_short`, `audio_too_long` | не та длительность | новая запись |
| 400 | `audio_silent` | в записи не слышно голоса | новая запись |
| 400 | `audio_rejected` | SpeechSuper не разобрал речь | новая запись |
| 401 | — | невалидный токен | открыть заново |
| 404 | `exercise_not_found` | упражнения нет | вернуться |
| 429 | `rate_limited` | больше 8 оценок в минуту | подождать |
| 429 | `daily_limit` | больше 200 оценок за сутки UTC | завтра |
| 502 | `speech_unavailable`, `speech_not_configured` | сбой сервиса | повтор |
| 504 | `speech_timeout` | таймаут сервиса | повтор |

```json
{ "detail": "Speech service unavailable", "code": "speech_unavailable" }
```

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
      "created_at": "2026-10-24T20:14:00+00:00",
      "fluency": 74,
      "rhythm": 81
    }
  ]
}
```

Правила:

- `words` сохраняется в `attempts` и содержит разбор по словам;
- у старых попыток `words` может быть `[]`;
- `fluency`, `rhythm`, `pronunciation`, `duration` есть только у попыток,
  где SpeechSuper их вернул;
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
    { "phoneme": "Р", "avg_score": 52, "trend": 8 },
    { "phoneme": "Ш", "avg_score": 61, "trend": null }
  ]
}
```

Правила:

- `attempts_count` — общее число попыток пользователя;
- `weak_phonemes` — звуки, у которых среднее по последним 10 оценкам ниже 70,
  по возрастанию; клиент показывает первые 5;
- `avg_score` — целое 0–100, округление половины вверх;
- `trend` — изменение `avg_score` относительно 10 предыдущих оценок звука;
  `null`, если их ещё нет;
- при отсутствии попыток: `{ "attempts_count": 0, "weak_phonemes": [] }`.

---

## Общие правила формата

- Все ключи JSON — `snake_case`.
- Все звуки — заглавные русские буквы: `"Р"`, `"Ш"`, `"Л"`.
- Ошибки приложения — `{ "detail": "<строка>", "code": "<код>" }`. `code` может
  отсутствовать: ошибка валидации 422 отдаёт `detail` списком, 401 — без кода.
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
- Клиент таймаутит `POST /api/v1/assess` через 60 секунд, остальные запросы —
  через 20 секунд. GET-запросы один раз повторяются при сетевой ошибке/5xx.
- Клиент отправляет WAV (`audio/wav`, PCM16, 16 кГц, моно) в поле `audio`; backend нормализует мобильные варианты 44,1/48 кГц и стерео;
  старые клиенты могут присылать webm/ogg.
- Клиент не хранит JWT и аудио на диске. Флаг онбординга хранится
  в `localStorage` (`shared_preferences`).
- Цвета на клиенте: `score > 75` — зелёный, `50–75` — жёлтый, `< 50` — красный.
  Цвет не единственный носитель информации: рядом всегда стоит число.
- Если `initData` пустой: в debug клиент открывает демо-режим, в release —
  экран «Откройте через Telegram».
