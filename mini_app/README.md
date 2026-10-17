# Речи — Mini App

Telegram Mini App для тренировки речи: восстановление после инсульта
и занятия с детьми с нарушениями речи.

Пользователь видит слово, записывает произношение, получает оценку 0–100
и разбивку по звукам. Слабые звуки попадают в прогресс.

> **Зона ответственности:** только этот каталог (`mini_app/**`).
> Backend живёт отдельно и не редактируется из этого проекта.

---

## Что уже есть

- Home: приветствие, прогресс, слабые звуки, старт тренировки.
- Exercise: слово, иллюстрация, звуки, запись WAV, отправка на проверку.
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
   `POST /api/auth/telegram`.
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
  HTTP-запросом и уходят в `POST /api/assess` multipart-полем `audio`.
- Аудио не сохраняется на клиенте и не пишется в БД (по контракту).
- Максимум записи — 10 секунд, минимум — 600 мс.
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
- [ ] «Начать тренировку» открывает слово.
- [ ] Микрофон спрашивает доступ и пишет WAV.
- [ ] Запись останавливается вручную и автоматически на 10 секундах.
- [ ] «Проверить произношение» показывает лоадер и результат.
- [ ] «Ещё раз» возвращает к тому же слову, «Дальше» даёт новое.
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
