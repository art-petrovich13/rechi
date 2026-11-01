# Rechi на Windows: полный запуск с нуля

Инструкция для пустого Windows-ПК: Docker, PostgreSQL, backend,
веб-интерфейс Mini App и HTTPS-туннель для Telegram.

Есть два пути:

- **Быстрый** — перенести уже собранный `mini_app/build/web`, не ставить
  Flutter. Нужны только Docker Desktop, Git и cloudflared.
- **С пересборкой клиента** — дополнительно поставить Flutter SDK.

Backend в обоих случаях собирается в Docker на Windows. **Не переноси
Docker-образ с Mac**: там arm64, на Windows x64 он не запустится нормально.

---

> На Windows порт 8080 часто занят NVIDIA Broadcast. Поэтому Rechi
> использует **8081**. Не меняй его на 8080, если не освободил порт.

## 1. Что скачать на Windows

Открой PowerShell **от администратора**:

```powershell
winget install --id Docker.DockerDesktop -e
winget install --id Git.Git -e
winget install --id Cloudflare.cloudflared -e
```

Для запасного туннеля Tunnelmole (если cloudflared не пройдёт):

```powershell
winget install --id OpenJS.NodeJS.LTS -e
```

Docker Desktop требует WSL2 и перезагрузку. Если WSL2 ещё нет:

```powershell
wsl --install
```

После перезагрузки запусти Docker Desktop и проверь:

```powershell
docker --version
docker compose version
cloudflared --version
```

Если `cloudflared` не находится — перезапусти PowerShell или переустанови
пакет. Путь обычно `C:\Program Files\cloudflared\cloudflared.exe`.

Flutter нужен **только** если будешь пересобирать веб-клиент:

1. Скачай Flutter SDK stable для Windows: <https://docs.flutter.dev/get-started/install/windows/web>
2. Распакуй, например, в `C:\src\flutter`.
3. Добавь `C:\src\flutter\bin` в `PATH`.
4. Проверь:

```powershell
flutter doctor
flutter config --enable-web
```

---

## 2. Что перенести с Mac

Нужны:

1. Папка проекта `rechi` (ветка `art/flutter`).
2. `backend/.env` — **секреты** (BOT_TOKEN, SpeechSuper keys, JWT_SECRET).
3. `mini_app/build/web/` — готовая веб-сборка, если не будешь ставить Flutter.
4. `compose.yaml` и `deploy/nginx.conf` уже лежат в проекте.

### Вариант A: через Git

На Mac:

```bash
cd /Users/nightly/Developer/projects/rechi
git push -u origin art/flutter
```

На Windows:

```powershell
cd C:\
git clone -b art/flutter <URL-репозитория> rechi
```

Потом отдельно скопируй `backend/.env` и, для быстрого пути,
`mini_app/build/web`.

### Вариант B: zip с Mac

На Mac:

```bash
cd /Users/nightly/Developer/projects
zip -r rechi-windows.zip rechi \
  -x 'rechi/.git/*' \
     'rechi/mini_app/.dart_tool/*' \
     'rechi/mini_app/build/web-demo/*' \
     'rechi/backend/.venv/*' \
     'rechi/**/.DS_Store'
```

В zip попадут `backend/.env` и `mini_app/build/web` — передавай его
через USB/зашифрованное облако, не в публичный чат.

На Windows распакуй в `C:\rechi`.

### Секреты

`backend/.env` содержит реальные ключи. Не коммить его и не отправляй
в открытый чат. После демо перевыпусти BOT_TOKEN у BotFather.

---

## 3. Проверка файлов

В PowerShell:

```powershell
cd C:\rechi
dir
dir backend\.env
dir mini_app\build\web\index.html
dir compose.yaml
```

Если `mini_app\build\web` нет — либо перенеси его с Mac, либо собери
Flutter на Windows (раздел 8).

---

## 4. Настрой `backend\.env`

Открой `C:\rechi\backend\.env` в VS Code/Notepad++ и проверь:

```env
BOT_TOKEN=<токен @rechi_bot>
PUBLIC_URL=https://<туннель>
JWT_SECRET=<длинная случайная строка>
SPEECH_SUPER_KEY=<appKey>
SPEECH_SUPER_SECRET=<secretKey>
SPEECH_SUPER_URL=https://api.speechsuper.com
SPEECH_SUPER_TIMEOUT_SECONDS=30
DATABASE_URL=postgresql+asyncpg://postgres:postgres@rechi-postgres:5432/rechi
```

Важно:

- `PUBLIC_URL` — **без** слэша на конце.
- `DATABASE_URL` можно не менять: `compose.yaml` переопределяет его на
  контейнер `db`.
- Файл сохраняй в **UTF-8 без BOM**.
- `PUBLIC_URL` нужно поставить **до** запуска API, иначе webhook уйдёт
  на старый адрес. Если уже запустил — пересоздай API после правки.

---

## 5. Сначала подними туннель

Открой **отдельное** окно PowerShell (его нельзя закрывать):

```powershell
cloudflared tunnel --url http://localhost:8081 --no-autoupdate
```

Скопируй строку вида:

```text
https://something.trycloudflare.com
```

Это и есть `PUBLIC_URL`.

### Если cloudflared не поднимается

В прошлый раз на Mac мешал Mullvad: он блокировал исходящий порт 7844.
На Windows проверь:

1. **Выключи VPN** (Mullvad/другой) и kill switch.
2. Разреши `cloudflared.exe` в Windows Firewall (исходящие).
3. Попробуй другую сеть — например, мобильный hotspot.
4. Перезапусти команду.

`--protocol http2` не поможет, если провайдер блокирует 7844: cloudflared
всё равно ходит на edge через 7844.

Запасной вариант без interstitial:

```powershell
npx -y tunnelmole 8081
```

Он даст `https://....tunnelmole.net`, работает через 443. Нужен Node.js.
Не используй Pinggy (рекламная заглушка Enter site) и ngrok free
(браузерное предупреждение), если нужен чистый вход в Telegram.

После получения URL:

```powershell
notepad C:\rechi\backend\.env
# PUBLIC_URL=https://....
```

Туннель должен смотреть на **8081** (nginx), не на 8001 и не на 8000.

---

## 6. Запуск

В `C:\rechi`:

```powershell
docker compose up -d --build
```

Первый запуск скачает Postgres, nginx и Python-зависимости; это может
занять 3–10 минут.

Проверь контейнеры:

```powershell
docker compose ps
```

Должны быть `db` (healthy), `api` (healthy), `web` (running).

Логи API:

```powershell
docker compose logs -f api
```

Там должно быть:

- миграции Alembic;
- `Добавлено упражнений: 90` (или меньше, если БД уже была);
- `Uvicorn running`;
- `Telegram webhook registered at https://<туннель>/bot/webhook`.

Остановить просмотр логов: `Ctrl+C` (контейнеры продолжат работать).

---

## 7. Проверка

Локально:

```powershell
curl.exe http://localhost:8081/health
curl.exe -I http://localhost:8081/app/
curl.exe http://localhost:8081/docs
```

Через туннель:

```powershell
curl.exe https://<туннель>/health
curl.exe -I https://<туннель>/app/
```

Затем открой **@rechi_bot** → `/start` → «Начать тренировку».
Должен открыться веб-интерфейс, авторизация — через Telegram initData.

Если API запустился до того, как ты вписал `PUBLIC_URL`:

```powershell
docker compose up -d --force-recreate api
```

---

## 8. Сборка клиента на Windows (если не переносишь build/web)

```powershell
cd C:\rechi\mini_app
flutter pub get
flutter build web --release `
  --base-href /app/ `
  --dart-define=SAME_ORIGIN_API=true `
  --no-web-resources-cdn `
  --no-wasm-dry-run
```

После сборки:

```powershell
cd C:\rechi
docker compose restart web
```

Флаг `SAME_ORIGIN_API=true` обязателен: клиент будет обращаться к `/api`
на том же домене, где открыт, а nginx проксирует запросы в API.
Без него клиент пойдёт на `localhost:8000` и в Telegram не заработает.

---

## 9. Что где работает

| Сервис | Порт | Назначение |
|---|---|---|
| `web` (nginx) | 8081 | `/app/` — статика, `/api/`, `/bot/`, `/health`, `/docs` |
| `api` (FastAPI) | 8001 → 8000 | backend, доступен снаружи только через nginx |
| `db` (Postgres 16) | внутри сети | база, наружу не открыта |
| cloudflared | — | HTTPS-туннель на `localhost:8081` |

Почему так:

- один origin → не нужен CORS;
- `PUBLIC_URL` и Mini App используют один и тот же домен;
- бот открывает `/app`, nginx редиректит на `/app/`;
- API, БД и клиент не светят лишние порты.

---

## 10. Обновления и повторный запуск

Обычный старт:

```powershell
cd C:\rechi
docker compose up -d
```

После изменения backend:

```powershell
docker compose up -d --build api
```

После пересборки клиента:

```powershell
docker compose restart web
```

После смены туннеля/`PUBLIC_URL`:

```powershell
docker compose up -d --force-recreate api
```

Клиент пересобирать при смене URL **не нужно** — он same-origin.

Сменить туннель:

1. останови старое окно cloudflared (`Ctrl+C`);
2. запусти новое;
3. обнови `PUBLIC_URL` в `backend\.env`;
4. `docker compose up -d --force-recreate api`.

---

## 11. Сброс базы

Только если не нужна история:

```powershell
cd C:\rechi
docker compose down
docker volume rm rechi_rechi_pgdata
docker compose up -d --build
```

`down -v` тоже удалит volume; это необратимо.

---

## 12. Частые проблемы

| Симптом | Что делать |
|---|---|
| Docker не стартует | включи WSL2, виртуализацию в BIOS, перезагрузи ПК |
| `port 8081 is already allocated` | `netstat -ano \| findstr :8081`; закрой процесс или поменяй `8081:80` в compose на `8081:80` и туннель на 8081 |
| `/app/` 404 | нет `mini_app/build/web/index.html`; собери/перенеси build, `docker compose restart web` |
| `/health` 502 | API не поднялся; `docker compose logs api` |
| `/assess` 502 | проверь `SPEECH_SUPER_KEY/SECRET/URL`; ключи trial активны; `docker compose logs api` |
| Telegram 530 | туннель умер или `PUBLIC_URL` не совпадает; новый URL + `--force-recreate api` |
| «Откройте через Telegram» | проверь `BOT_TOKEN` и `initData`; не открывай `/app` в обычном браузере |
| `.env` не читается | UTF-8 без BOM, без пробелов вокруг `=` |
| Docker build падает на сети | проверь VPN/прокси; повтори `docker compose build api` |
| Бот не отвечает | `docker compose logs -f api`; webhook должен быть зарегистрирован |

---

## 13. Мини-чеклист на завтра

- [ ] Docker Desktop + WSL2 установлены, `docker compose version` работает.
- [ ] Git/cloudflared (и Node для Tunnelmole) установлены.
- [ ] `C:\rechi` содержит `backend\.env`, `mini_app\build\web`, `compose.yaml`.
- [ ] `PUBLIC_URL` в `.env` обновлён после запуска туннеля.
- [ ] cloudflared смотрит на `http://localhost:8081`.
- [ ] `docker compose up -d --build` — все три контейнера healthy/running.
- [ ] `http://localhost:8081/app/` открывается.
- [ ] `https://<туннель>/health` отвечает 200.
- [ ] В логах API есть `webhook registered`.
- [ ] @rechi_bot → `/start` → Mini App открывается.
EOF
echo "guide written"; wc -l WINDOWS_SETUP.md
