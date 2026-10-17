#!/usr/bin/env node
/**
 * Локальный dev-прокси для проверки Mini App вместе с backend.
 *
 * Что делает:
 *  - раздаёт build/web по /app/ (как продовый backend);
 *  - проксирует /api, /bot, /health, /docs на backend;
 *  - подставляет валидный Telegram.WebApp.initData для тестового пользователя,
 *    подписанный DEV_BOT_TOKEN (он должен совпадать с BOT_TOKEN backend).
 *
 * Это только для локальной разработки. Не использовать в проде.
 *
 * Пример:
 *   flutter build web --release --base-href /app/ \
 *     --dart-define=API_BASE_URL=http://localhost:8080 \
 *     --no-web-resources-cdn
 *
 *   DEV_BOT_TOKEN=123456:TEST_TOKEN_FOR_LOCAL \
 *   BACKEND_URL=http://127.0.0.1:8001 \
 *   node tool/dev_proxy.mjs
 *
 * Открыть: http://localhost:8080/app/
 */

import crypto from 'node:crypto';
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');
const webDir = process.env.WEB_DIR
  ? path.resolve(process.env.WEB_DIR)
  : path.join(projectRoot, 'build', 'web');
const backendUrl = new URL(process.env.BACKEND_URL ?? 'http://127.0.0.1:8001');
const port = Number(process.env.PORT ?? 8080);
const botToken = process.env.DEV_BOT_TOKEN;
const userName = process.env.DEV_USER_NAME ?? 'Иван';

if (!botToken) {
  console.error(
    'DEV_BOT_TOKEN is required. It must be the same value as BOT_TOKEN in backend .env.',
  );
  process.exit(1);
}

if (!fs.existsSync(path.join(webDir, 'index.html'))) {
  console.error(`No Flutter build found at ${webDir}`);
  console.error(
    'Build it first: flutter build web --release --base-href /app/ ' +
      '--dart-define=API_BASE_URL=http://localhost:8080 --no-web-resources-cdn',
  );
  process.exit(1);
}

const mimeTypes = new Map([
  ['.html', 'text/html; charset=utf-8'],
  ['.js', 'text/javascript; charset=utf-8'],
  ['.mjs', 'text/javascript; charset=utf-8'],
  ['.json', 'application/json; charset=utf-8'],
  ['.wasm', 'application/wasm'],
  ['.css', 'text/css; charset=utf-8'],
  ['.png', 'image/png'],
  ['.ico', 'image/x-icon'],
  ['.svg', 'image/svg+xml'],
  ['.map', 'application/json; charset=utf-8'],
  ['.otf', 'font/otf'],
  ['.ttf', 'font/ttf'],
  ['.woff', 'font/woff'],
  ['.woff2', 'font/woff2'],
  ['.txt', 'text/plain; charset=utf-8'],
]);

/**
 * Формирует initData так же, как это делает Telegram.
 * Backend проверяет HMAC-SHA256 с ключом "WebAppData" + BOT_TOKEN.
 */
function createDevInitData() {
  const fields = {
    query_id: 'dev-local',
    user: JSON.stringify({ id: 1, first_name: userName }),
    auth_date: String(Math.floor(Date.now() / 1000)),
  };

  const dataCheckString = Object.keys(fields)
    .sort()
    .map((key) => `${key}=${fields[key]}`)
    .join('\n');

  const secret = crypto
    .createHmac('sha256', 'WebAppData')
    .update(botToken)
    .digest();
  const hash = crypto
    .createHmac('sha256', secret)
    .update(dataCheckString)
    .digest('hex');

  return new URLSearchParams({ ...fields, hash }).toString();
}

function telegramInjection() {
  const initData = createDevInitData();
  return `<script>
  (() => {
    const existing = window.Telegram && window.Telegram.WebApp;
    const hasRealTelegramData =
      existing &&
      existing.initData &&
      existing.platform &&
      existing.platform !== 'unknown';

    // В настоящем Telegram ничего не подменяем: SDK уже дал initData.
    if (hasRealTelegramData) {
      return;
    }

    window.Telegram = {
      WebApp: {
        initData: ${JSON.stringify(initData)},
        initDataUnsafe: {},
        platform: 'android',
        version: '7.10',
        colorScheme: 'light',
        themeParams: {},
        isExpanded: false,
        isActive: true,
        viewportHeight: window.innerHeight,
        viewportStableHeight: window.innerHeight,
        headerColor: '#F4F7FB',
        backgroundColor: '#F4F7FB',
        bottomBarColor: '#F4F7FB',
        isClosingConfirmationEnabled: false,
        isVerticalSwipesEnabled: true,
        isFullscreen: false,
        isOrientationLocked: false,
        ready() {},
        expand() {},
        setHeaderColor() {},
        setBackgroundColor() {},
        setBottomBarColor() {},
        isVersionAtLeast() { return true; },
        close() {},
        onEvent() {},
        offEvent() {},
        BackButton: { show() {}, hide() {}, onClick() {}, offClick() {}, isVisible: false },
        MainButton: { setText() {}, show() {}, hide() {}, onClick() {}, offClick() {}, setParams() {}, isVisible: false },
        HapticFeedback: { impactOccurred() {}, notificationOccurred() {}, selectionChanged() {} },
      },
    };
  })();
  </script>`;
}

function serveFlutterFile(request, response, pathname) {
  const relativePath = pathname.slice('/app'.length) || '/index.html';
  const safeRelative = path
    .normalize(relativePath)
    .replace(/^(\.\.[/\\])+/, '')
    .replace(/^[/\\]+/, '');
  let filePath = path.join(webDir, safeRelative);

  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
    filePath = path.join(filePath, 'index.html');
  }

  if (!filePath.startsWith(webDir) || !fs.existsSync(filePath)) {
    response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end('Not found');
    return;
  }

  const extension = path.extname(filePath).toLowerCase();
  const contentType =
    mimeTypes.get(extension) ?? 'application/octet-stream';
  let content = fs.readFileSync(filePath);

  if (extension === '.html') {
    content = Buffer.from(
      content
        .toString('utf8')
        .replace('</head>', `${telegramInjection()}\n</head>`),
    );
  }

  response.writeHead(200, {
    'Content-Type': contentType,
    'Cache-Control': 'no-store',
    'Content-Length': content.length,
  });
  response.end(content);
}

function proxyToBackend(request, response) {
  const target = new URL(request.url, backendUrl);
  const headers = { ...request.headers, host: backendUrl.host };

  const proxyRequest = http.request(
    target,
    { method: request.method, headers },
    (proxyResponse) => {
      response.writeHead(proxyResponse.statusCode ?? 502, proxyResponse.headers);
      proxyResponse.pipe(response);
    },
  );

  proxyRequest.on('error', (error) => {
    console.error(`Proxy error for ${request.url}:`, error.message);
    if (!response.headersSent) {
      response.writeHead(502, { 'Content-Type': 'application/json' });
    }
    response.end(JSON.stringify({ detail: 'Backend is unavailable' }));
  });

  request.pipe(proxyRequest);
}

const server = http.createServer((request, response) => {
  const url = new URL(request.url ?? '/', `http://localhost:${port}`);
  const pathname = url.pathname;

  if (pathname === '/' || pathname === '/app') {
    response.writeHead(302, { Location: '/app/' });
    response.end();
    return;
  }

  if (pathname.startsWith('/app/')) {
    serveFlutterFile(request, response, pathname);
    return;
  }

  if (
    pathname.startsWith('/api/') ||
    pathname.startsWith('/bot') ||
    pathname === '/health' ||
    pathname === '/openapi.json' ||
    pathname.startsWith('/docs')
  ) {
    proxyToBackend(request, response);
    return;
  }

  response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
  response.end('Not found');
});

server.listen(port, () => {
  console.log(`Rechi dev proxy: http://localhost:${port}/app/`);
  console.log(`Backend: ${backendUrl.origin}`);
  console.log(`Flutter build: ${webDir}`);
  console.log(`Dev user: ${userName} (id=1)`);
  console.log('Do not use this server in production.');
});
