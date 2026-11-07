# Речи (Rechi)

Тренажёр произношения для взрослых после инсульта и детей с нарушениями речи.
Сейчас это MVP в виде Telegram Mini App, цель — мобильное приложение для iOS и
Android на том же Flutter.

Пользователь произносит слово, словосочетание или предложение, сервис SpeechSuper
оценивает запись, приложение показывает балл по звукам и словам и копит слабые
звуки для тренировки.

## Архитектура

```
Telegram → Mini App (Flutter Web)
              │ Bearer JWT
              ▼
nginx ── /app/ статика, /api/ и /bot/ → FastAPI + aiogram ──→ SpeechSuper
                                           │
                                           ▼
                                      PostgreSQL 16
```

| Папка | Что внутри |
|---|---|
| `mini_app/` | клиент на Flutter: экраны, запись WAV, авторизация, демо-режим |
| `backend/` | FastAPI, бот, оценка речи, миграции, упражнения в `seed.py` |
| `deploy/`, `compose.yaml` | nginx и запуск в Docker |

## Быстрый старт

Нужны Docker, Flutter и файл `backend/.env` (образец в `backend/.env.example`).
Обязательны `BOT_TOKEN` и `JWT_SECRET`: без них API не запустится.

```bash
cd mini_app
flutter build web --release --base-href /app/ --dart-define=SAME_ORIGIN_API=true --no-web-resources-cdn --no-wasm-dry-run
```

```bash
docker compose up -d --build
```

Приложение откроется на <http://localhost:8081/app/>, но вход работает только
из Telegram. Для разработки без него есть демо-режим и dev-прокси, см.
[`mini_app/README.md`](mini_app/README.md).

## Проверки

```bash
cd mini_app && flutter analyze && flutter test
```

Backend требует Python 3.11 или 3.12 (модуль `audioop` удалён в 3.13):

```bash
cd backend && python -m unittest discover -s tests -t .
```

```bash
cd backend && alembic check
```

Интеграционные тесты идут на настоящем PostgreSQL и очищают таблицы, поэтому
запускаются только на базе с суффиксом `_test` и с флагом:

```bash
cd backend && RECHI_INTEGRATION=1 DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/rechi_test python -m unittest discover -s tests -t .
```

Упражнения лежат в `backend/app/content/exercises.json`, ударение отмечается
знаком `+`. Транскрипцию, категорию и сложность сервер считает сам, а тест
`tests/content` проверяет разметку и покрытие звуков.

## Документы

| Файл | О чём |
|---|---|
| [`ROADMAP.md`](ROADMAP.md) | решения по продукту, целевая архитектура, план |
| [`PROJECT_ANALYSIS.md`](PROJECT_ANALYSIS.md) | полный разбор проекта и код-ревью |
| [`API_CONTRACT.md`](API_CONTRACT.md) | контракт клиента и сервера |
| [`WINDOWS_SETUP.md`](WINDOWS_SETUP.md) | развёртывание на Windows с туннелем |
| [`MVP_IMPROVEMENT_PLAN.md`](MVP_IMPROVEMENT_PLAN.md) | история этапов 1–2 |
