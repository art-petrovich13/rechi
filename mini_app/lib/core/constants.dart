/// Настройки приложения и адреса API.
library;

/// Базовый URL backend.
///
/// Прод: `--dart-define=API_BASE_URL=https://<домен>`.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

/// Использовать origin страницы как базу API.
///
/// Удобно для dev-прокси и HTTPS-туннелей: клиент и backend живут
/// на одном origin, поэтому туннель можно менять без пересборки.
const bool useSameOriginApi = bool.fromEnvironment(
  'SAME_ORIGIN_API',
  defaultValue: false,
);

/// Принудительный демо-режим без backend.
///
/// Сборка для показа: `--dart-define=MOCK_API=true`.
const bool useMockApi = bool.fromEnvironment('MOCK_API', defaultValue: false);

/// Эндпоинты Frozen API Contract.
const String epAuthTelegram = '/api/v1/auth/telegram';
const String epExercisesNext = '/api/v1/exercises/next';
const String epAssess = '/api/v1/assess';
const String epProgress = '/api/v1/progress';
const String epHistory = '/api/v1/history';

/// Таймауты запросов.
const Duration apiTimeout = Duration(seconds: 20);
const Duration assessTimeout = Duration(seconds: 60);
const Duration retryDelay = Duration(milliseconds: 350);

/// Параметры записи.
const int recordingSampleRate = 16000;
const int recordingChannels = 1;
const int maxRecordingSeconds = 20;
const Duration minRecordingDuration = Duration(milliseconds: 600);
const String recordingFileName = 'recording.wav';
const String recordingMimeType = 'audio/wav';

/// Порог, ниже которого звук считается проблемным.
const int problemScoreThreshold = 60;

/// Тексты бренда.
const String appName = 'Речи';
const String appTagline = 'Тренажёр речи';
