# Rechi Backend — шпаргалка для Артёма

## Что готово

- FastAPI API с префиксом `/api/v1`.
- Авторизация Telegram Mini App через проверку `initData` и выдачу JWT.
- PostgreSQL + SQLAlchemy + Alembic.
- Выдача случайного упражнения с фильтром по категории
  (`word` / `phrase` / `sentence`).
- Проверка WAV (до 20 секунд) и оценка произношения через SpeechSuper.
- Разбор по словам: в `/assess` возвращается `words[]` с баллом и фонемами
  каждого слова.
- Поддержка слов, словосочетаний и коротких предложений: для слова
  вызывается `word.eval.ru`, для фразы — `sent.eval.ru`; фонемы
  нормализуются в кириллицу.
- Для фраз возвращаются `fluency`, `rhythm`, `pronunciation`, `speed`,
  `duration`; на клиенте — карточка «Темп и ритм».
- Сохранение попыток, per-word разбора (`attempts.words`) и расчёт слабых
  фонем.
- История последних попыток: `GET /api/v1/history?limit=20`.
- Фильтр упражнений по слабому звуку: `GET /api/v1/exercises/next?focus=Р`.
- 90 упражнений в seed: 43 слова, 25 словосочетаний, 22 предложения.
- Telegram-бот на aiogram: `/start`, `/help`, Web App-кнопка и webhook.

Swagger: `http://localhost:8000/docs`  
Health check: `http://localhost:8000/health`

## API для Mini App

Все защищённые запросы используют заголовок:

```http
Authorization: Bearer <JWT>
```

| Метод | Путь | Назначение |
|---|---|---|
| `POST` | `/api/v1/auth/telegram` | Обмен Telegram `initData` на JWT |
| `GET` | `/api/v1/exercises/next` | Получение случайного упражнения |
| `POST` | `/api/v1/assess` | Отправка записи на оценку |
| `GET` | `/api/v1/history` | Последние попытки с разбором по словам |
| `GET` | `/api/v1/progress` | Прогресс текущего пользователя |

Авторизация:

```json
{
  "initData": "значение Telegram.WebApp.initData без изменений"
}
```

Ответ содержит `token` и объект `user`. Полученный токен используется во всех
следующих запросах.

Оценка произношения отправляется как `multipart/form-data`:

- `audio` — файл `recording.wav`, MIME `audio/wav`;
- `exercise_id` — ID упражнения.

Требования к записи: WAV, PCM signed 16-bit little-endian, 16 kHz, mono,
длительность 0.6–20 секунд, размер не более 8 МБ. Backend нормализует WAV (44,1/48 кГц, моно/стерео) в 16 кГц/моно. Аудио не сохраняется
ни на диск, ни в PostgreSQL.

`text` упражнения может быть словом, словосочетанием или коротким
предложением; `phonemes` — уникальные звуки в порядке первого появления. `problematic` содержит фонемы
с баллом ниже 60 и отсортирован по возрастанию балла. В `/progress` слабой
считается фонема со средней оценкой ниже 70.

## Локальный запуск

```bash
cd backend
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

В `.env` обязательно задать минимум:

```env
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/rechi
JWT_SECRET=случайная-длинная-строка
BOT_TOKEN=токен-от-BotFather
SPEECH_SUPER_KEY=
SPEECH_SUPER_SECRET=
```

Подготовка БД и запуск:

```bash
alembic upgrade head
python seed.py
uvicorn app.main:app --reload
```

`seed.py` безопасно запускать повторно: уже существующие упражнения не
дублируются.

## Docker

```bash
cd backend
docker build -t rechi-backend .
docker run --rm --env-file .env -p 8000:8000 rechi-backend
```

Если PostgreSQL запущен на macOS-хосте, внутри контейнера в `DATABASE_URL`
нужно использовать `host.docker.internal`, а не `localhost`. Если API и БД
находятся в одной Docker-сети — используется имя сервиса PostgreSQL.

Миграции и seed можно запускать тем же образом, заменяя команду контейнера:

```bash
docker run --rm --env-file .env rechi-backend alembic upgrade head
docker run --rm --env-file .env rechi-backend python seed.py
```

## Telegram-бот

Для регистрации webhook дополнительно нужны:

```env
PUBLIC_URL=https://публичный-домен
TELEGRAM_WEBHOOK_SECRET=случайная-секретная-строка
```

При старте backend регистрирует `${PUBLIC_URL}/bot/webhook`. Кнопка `/start`
открывает `${PUBLIC_URL}/app`. Саму Mini App и раздачу её сборки предоставляет
frontend-часть проекта.

Без `BOT_TOKEN` или `PUBLIC_URL` бот отключён, но HTTP API продолжает работать.

## Проверка

```bash
cd backend
source .venv/bin/activate
python -m unittest discover -s tests -v
```

Автотесты не обращаются к Telegram и SpeechSuper. Реальная интеграционная
проверка требует рабочих ключей и публичного HTTPS-адреса.

## Важно при интеграции

- Актуальный API начинается с `/api/v1`, не с `/api`.
- Backend принимает на `/assess` только описанный выше WAV.
- `.env`, токены, ключи, `.venv` и `__pycache__` в Git не добавляются.
- Backend не содержит Flutter-сборку и не изменяет `mini_app/**`.
