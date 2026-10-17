# Rechi Backend

Минимальный backend проекта на FastAPI.

Краткая памятка для интеграции с Mini App находится в
[`HANDOFF_ARTEM.md`](HANDOFF_ARTEM.md).

## Запуск в Docker

Из директории `backend`:

```bash
docker build -t rechi-backend .
docker run --rm -p 8000:8000 rechi-backend
```

После запуска доступны:

- API: <http://localhost:8000>
- Swagger UI: <http://localhost:8000/docs>
- Проверка состояния: <http://localhost:8000/health>

## Telegram-бот

Бот работает через webhook внутри FastAPI. Для включения укажите в `.env`:

```env
BOT_TOKEN=токен-от-BotFather
PUBLIC_URL=https://ваш-публичный-домен
TELEGRAM_WEBHOOK_SECRET=случайная-секретная-строка
```

После запуска backend зарегистрирует webhook
`https://ваш-публичный-домен/bot/webhook`. Команда `/start` покажет кнопку,
открывающую Mini App по адресу `https://ваш-публичный-домен/app`.

Для локальной проверки `PUBLIC_URL` должен быть публичным HTTPS-адресом,
например адресом HTTPS-туннеля на локальный порт `8000`.

## Локальный запуск

```bash
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Локальные секреты следует хранить в `.env`. За основу можно взять
`.env.example`; сам `.env` нельзя добавлять в Git.

## Миграции базы данных

Локальный PostgreSQL 16 запускается в отдельном контейнере:

```bash
docker start rechi-postgres
```

Остановить базу:

```bash
docker stop rechi-postgres
```

Данные хранятся в Docker volume `rechi_postgres_data` и не удаляются при
остановке контейнера.

После запуска PostgreSQL применить миграции можно из директории `backend`:

```bash
alembic upgrade head
```

Откат последней миграции:

```bash
alembic downgrade -1
```

Загрузить начальные упражнения (команда безопасна для повторного запуска):

```bash
python seed.py
```
