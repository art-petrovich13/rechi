# Речи — Mini App

Telegram Mini App для тренировки речи: восстановление после инсульта
и занятия с детьми с нарушениями речи.

Пользователь выбирает категорию (слово, словосочетание или предложение), записывает произношение и получает оценку 0–100 с разбором по звукам и словам
и разбивку по звукам. Слабые звуки попадают в прогресс.

> **Зона ответственности:** только этот каталог (`mini_app/**`).
> Backend живёт отдельно и не редактируется из этого проекта.

---

## Что уже есть

- Home: приветствие, прогресс, слабые звуки, старт тренировки.
- Exercise: слово/фраза/предложение, иллюстрация, звуки, запись WAV, отправка на проверку.
- Result: общая оценка, баллы по звукам, советы по артикуляции,
  «Ещё раз» / «Дальше».
- Авторизация через `Telegram.WebApp.initData` → JWT.
- Единый `ApiClient` с таймаутами, retry для GET и понятными ошибками.
- Демо-режим без backend (`MOCK_API=true`) с правдоподобными оценками.
- Адаптив под 320–560 px, крупные кнопки и шрифты, Semantics-подписи.
- Онбординг «Как заниматься» (показывается один раз, хранится локально).

---

## Скриншоты

Сняты в headless Chrome на viewport 390×844 (DPR 2).

| Home | Упражнение |
|---|---|
| ![Home](docs/screenshots/home.png) | ![Упражнение](docs/screenshots/exercise.png) |

| Результат | «Как заниматься» |
|---|---|
| ![Результат](docs/screenshots/result.png) | ![Онбординг](docs/screenshots/how-it-works.png) |

Ещё есть [`auth-error.png`](docs/screenshots/auth-error.png) — экран
«Откройте через Telegram» в production-сборке без `initData`.

## Стек

| Компонент | Версия |
|---|---|
| Flutter | 3.47.6 stable |
| Dart | 3.13.5 |
| `record` | 7.1.2 (WAV-энкодер на web) |
| `telegram_web_app` | 0.3.3 |
| `http` | 1.6.0 |
| `provider` | 6.1.5 |
| `http_parser` | 4.1.2 |
| `shared_preferences` | 2.5.6 |

Почему `record 7.x`, а не 5.x из первоначального плана: Flutter 3.47
рассчитан на актуальную ветку пакета, а на web нужен WAV без `dart:io`.
API при этом тот же: `AudioRecorder`, `RecordConfig`, `start/stop`.

---

## Структура

```
lib/
├── main.dart                 # bootstrap, providers, MaterialApp
├── core/
│   ├── constants.dart        # URL, эндпоинты, лимиты
│   ├── api_client.dart       # все HTTP-запросы
│   ├── api_exception.dart    # ошибки с текстом для UI
│   ├── auth_service.dart     # initData → JWT, демо-режим
│   ├── progress_service.dart # загрузка прогресса
│   ├── telegram_bridge.dart  # безопасная обёртка Telegram.WebApp
│   ├── audio_recorder.dart   # запись WAV 16 кГц / моно
│   └── mock_backend.dart     # демо-данные
├── models/                   # User, Exercise, Assessment, Progress
├── screens/
│   ├── auth_gate.dart        # splash / home / auth error
│   ├── home_screen.dart
│   ├── exercise_screen.dart
│   ├── result_screen.dart
│   └── splash_screen.dart, auth_error_screen.dart
├── widgets/                  # чипы, оценки, кнопка записи, карточки
└── theme/                    # палитра, типографика, состояния
```

---

## Быстрый старт

```bash
cd mini_app
flutter pub get

# Демо без backend (рекомендуется для UI):
flutter run -d chrome --dart-define=MOCK_API=true
```

В debug-сборке без `initData` демо включается автоматически, поэтому
`flutter run -d chrome` тоже откроет приложение с тестовыми данными.

### С реальным backend

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000
```

Backend должен разрешать CORS для origin, с которого открыт Flutter
(например, `http://localhost:8080`), или раздавать `build/web` с того же
домена.

---

## Локальная проверка с реальным backend (без Telegram)

Backend можно поднять в Docker, а Mini App — через dev-прокси, который
раздаёт сборку по `/app/` и подставляет валидный `initData` тестового
пользователя. Backend при этом по-настоящему проверяет HMAC и JWT.

### 1. Backend + PostgreSQL

Из корня репозитория:

```bash
cd backend
docker build -t rechi-backend .

docker network create rechi-net 2>/dev/null || true

docker run -d --name rechi-postgres --network rechi-net \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=rechi \
  -v rechi_pgdata:/var/lib/postgresql/data postgres:16

cp .env.example .env
# В .env минимум:
# BOT_TOKEN=123456:TEST_TOKEN_FOR_LOCAL
# JWT_SECRET=local-dev-secret-please-change
# DATABASE_URL=postgresql+asyncpg://postgres:postgres@rechi-postgres:5432/rechi
# SPEECH_SUPER_KEY=local
# SPEECH_SUPER_SECRET=local
# SPEECH_SUPER_URL=http://host.docker.internal:9000

docker run --rm --network rechi-net --env-file .env rechi-backend alembic upgrade head
docker run --rm --network rechi-net --env-file .env rechi-backend python seed.py
docker run -d --name rechi-api --network rechi-net --env-file .env -p 8001:8000 rechi-backend
```

`8001`, потому что на этой машине порт `8000` уже занят другим проектом.
Если свободен — можно использовать `-p 8000:8000`.

Swagger: <http://localhost:8001/docs>  
Health: <http://localhost:8001/health>

### 2. Заглушка SpeechSuper (если нет реальных ключей)

```bash
cd mini_app
python3 tool/fake_speechsuper.py
```

Она возвращает баллы по буквам слова: первый звук проблемный, остальные
хорошие. Это только для локального UI-теста, не для оценки качества речи.
Если `SPEECH_SUPER_KEY/SECRET` пустые или заглушка не запущена, `/assess`
вернёт `502`.

### 3. Сборка клиента и dev-прокси

```bash
cd mini_app
flutter build web --release \
  --base-href /app/ \
  --dart-define=SAME_ORIGIN_API=true \
  --no-web-resources-cdn

DEV_BOT_TOKEN=123456:TEST_TOKEN_FOR_LOCAL \
BACKEND_URL=http://127.0.0.1:8001 \
node tool/dev_proxy.mjs
```

Открыть: <http://localhost:8080/app/>

`SAME_ORIGIN_API=true` означает, что клиент ходит в `/api` на том же
домене, где открыт. Поэтому один и тот же билд работает и на
`localhost:8080`, и на HTTPS-туннеле — пересобирать под каждый URL не нужно.

`DEV_BOT_TOKEN` должен совпадать с `BOT_TOKEN` backend. Прокси:
- раздаёт Flutter-сборку по `/app/`;
- проксирует `/api`, `/bot`, `/health`, `/docs` на backend;
- в обычном браузере подставляет тестовый `initData`, а в настоящем
  Telegram не вмешивается (там SDK даёт реальные данные).

Первый запуск покажет онбординг «Как заниматься» — это нормально.
Дальше можно пройти весь флоу: Home → запись → оценка → прогресс.

Не запускайте `flutter run -d chrome` напрямую против backend: в backend
нет CORS. Для локальной проверки используйте dev-прокси, он отдаёт
клиент и API с одного origin.

### 4. Настоящий Telegram

```bash
cloudflared tunnel --url http://localhost:8080
```

1. Создайте бота у `@BotFather`, положите настоящий токен в `BOT_TOKEN`.
2. Укажите `PUBLIC_URL=https://<tunnel-домен>` и перезапустите `rechi-api`
   (при старте backend зарегистрирует webhook).
3. В Telegram отправьте боту `/start` и нажмите «Начать тренировку».

Прокси проксирует и `/bot/webhook`, поэтому туннель можно направлять
на него. В настоящем Telegram подмена `initData` не срабатывает.

> Для production backend сам должен раздавать `/app` (или стоять за
> nginx/Caddy). Сейчас в backend статики нет: `GET /app` возвращает 404,
> а кнопка бота ведёт именно на `/app`. Это нужно согласовать с Андреем.

## Сборка

### Демо для показа (без backend)

```bash
flutter build web --release \
  --dart-define=MOCK_API=true \
  --no-web-resources-cdn \
  --no-wasm-dry-run
```

### Production

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://rechi.example.com \
  --no-web-resources-cdn \
  --no-wasm-dry-run
```

Результат — `build/web`. Его нужно раздать по HTTPS (FastAPI StaticFiles,
nginx или Caddy). Mini App в Telegram работает только по HTTPS.

Для мероприятия лучше собирать с `--no-web-resources-cdn`: тогда CanvasKit
загружается с вашего домена, а не с `gstatic.com`, и приложение меньше
зависит от внешнего интернета. Если обновления должны подхватываться сразу,
добавьте `--pwa-strategy=none` (отключает service worker).

---

## Переменные сборки

| Dart define | Значение по умолчанию | Назначение |
|---|---|---|
| `API_BASE_URL` | `http://localhost:8000` | адрес backend |
| `SAME_ORIGIN_API` | `false` | брать origin страницы как базу API (удобно для прокси/туннеля) |
| `MOCK_API` | `false` | принудительный демо-режим |

```bash
# Пример production для мероприятия
flutter build web --release \
  --dart-define=API_BASE_URL=https://rechi.example.com \
  --dart-define=MOCK_API=false
```

`build/web` не коммитится. Передайте его backend-разработчику или
разверните отдельно.

### Куда монтировать статику

- Если FastAPI/nginx раздаёт `build/web` **с корня** (`https://rechi.example.com/`),
  используйте сборку по умолчанию.
- Если статика живёт по пути **`/app/`** (как в общем плане MVP), добавьте
  `--base-href /app/`:

```bash
flutter build web --release \
  --base-href /app/ \
  --dart-define=API_BASE_URL=https://rechi.example.com \
  --no-web-resources-cdn \
  --pwa-strategy=none \
  --no-wasm-dry-run
```

Уточните путь у Андрея до деплоя: от `base href` зависят пути к `assets/`
и `canvaskit/`. API-запросы всегда идут на абсолютный `API_BASE_URL`.

---

## Telegram Mini App

1. `web/index.html` подключает `https://telegram.org/js/telegram-web-app.js`
   **до** Flutter.
2. Бот присылает кнопку `web_app` с HTTPS-URL.
3. Flutter читает `Telegram.WebApp.initData` и отправляет в
   `POST /api/v1/auth/telegram`.
4. Backend проверяет `hash` и выдаёт JWT.
5. Дальше клиент работает как обычное web-приложение с
   `Authorization: Bearer <token>`.

Особенности:

- `initData` — только `Telegram.WebApp.initData`, не `initDataUnsafe`.
- `ready()` / `expand()` вызываются один раз при старте.
- Цвета header/background синхронизируются со светлой темой.
- Вне Telegram `initData` пустой: в debug включается демо, в release
  показывается экран «Откройте через Telegram».

---

## Аудио

- WAV, PCM16, 16 кГц, моно — максимально совместимый формат для
  SpeechSuper и простой в отладке.
- На web `record.stop()` возвращает `blob:` URL; байты читаются
  HTTP-запросом и уходят в `POST /api/v1/assess` multipart-полем `audio`.
- Аудио не сохраняется на клиенте и не пишется в БД (по контракту).
- Максимум записи — 20 секунд, минимум — 600 мс.
- Если микрофон не отвечает 15 секунд, показывается понятная ошибка
  и кнопка повтора. В демо-режиме доступен фолбэк
  «Продолжить без записи (демо)».

Проверить запись нужно в реальном браузере/Telegram: headless Chrome
не отдаёт `getUserMedia` даже с фейковым устройством.

---

## Проверки

```bash
flutter analyze          # 0 issues
flutter test             # модели, API, мок, виджеты
flutter build web --release --no-wasm-dry-run
```

Ручной чек-лист перед мероприятием:

- [ ] Home открывается, прогресс загружается (0 попыток — пустое состояние).
- [ ] «Начать тренировку» открывает выбранную категорию.
- [ ] Микрофон спрашивает доступ и пишет WAV.
- [ ] Запись останавливается вручную и автоматически на 20 секундах.
- [ ] «Проверить произношение» показывает лоадер и результат.
- [ ] «Ещё раз» возвращает к тому же заданию, «Дальше» даёт новое.
- [ ] После возврата на Home прогресс обновился.
- [ ] В Telegram кнопка Mini App открывает HTTPS-URL.
- [ ] Ошибка 502 показывает «Сервис анализа речи недоступен».
- [ ] Нет сети → понятное сообщение и retry.

---

## Известные ограничения

- Реальную запись и Telegram WebView нельзя проверить в headless CI —
  нужен ручной прогон на устройстве.
- iOS Telegram WebView исторически капризен к MediaRecorder; поэтому
  используется WAV через Web Audio, а не WebM/Opus.
- В `phonemes` возможны повторяющиеся буквы («шапка»), а
  `phoneme_scores` содержит уникальные звуки — один балл на звук.
- Пока нет TTS-озвучки слова и сохранения аудио для датасета.
- `shared_preferences` сейчас хранит только флаг онбординга; JWT не
  кэшируется (безопасность на общем устройстве).

---

## API

Полный контракт — [`../API_CONTRACT.md`](../API_CONTRACT.md).
Изменения полей и путей — только через PR с backend-разработчиком.

---

## Полезные команды

```bash
# посмотреть, что занимает место в web-сборке
du -sh build/web
find build/web -maxdepth 2 -type f -exec du -h {} + | sort -rh | head

# проверить сборку локально
python3 -m http.server 8081 --directory build/web

# форматирование
dart format lib test
```
