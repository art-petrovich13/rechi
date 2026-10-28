import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mini_app/core/api_exception.dart';
import 'package:mini_app/core/constants.dart';
import 'package:mini_app/core/mock_backend.dart';
import 'package:mini_app/models/assessment.dart';
import 'package:mini_app/models/auth_response.dart';
import 'package:mini_app/models/exercise.dart';
import 'package:mini_app/models/history.dart';
import 'package:mini_app/models/progress.dart';
import 'package:mini_app/models/training_category.dart';

/// Единый HTTP-клиент приложения.
///
/// Все запросы к backend идут только через этот класс.
class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    MockBackend? mockBackend,
    bool? mock,
  }) : _baseUrl = _normalize(baseUrl ?? _defaultBaseUrl()),
       _http = httpClient ?? http.Client(),
       _mock = mockBackend ?? ((mock ?? useMockApi) ? MockBackend() : null);

  static String _defaultBaseUrl() {
    if (!useSameOriginApi) {
      return apiBaseUrl;
    }
    final String origin = Uri.base.origin;
    if (origin.isEmpty || origin == 'null') {
      return apiBaseUrl;
    }
    return origin;
  }

  final String _baseUrl;
  final http.Client _http;
  MockBackend? _mock;
  String? _token;

  bool get isMock => _mock != null;
  String get baseUrl => _baseUrl;
  String? get token => _token;

  void setToken(String? token) {
    _token = token;
  }

  /// Включает демо-бэкенд (например, в debug без Telegram).
  void enableMockMode() {
    _mock ??= MockBackend();
  }

  void close() {
    _http.close();
  }

  /// `POST /api/auth/telegram`.
  Future<AuthResponse> authTelegram(String initData) async {
    final MockBackend? mock = _mock;
    if (mock != null) {
      return mock.auth(initData);
    }

    final http.Response response = await _send(
      () => _http.post(
        _uri(epAuthTelegram),
        headers: _jsonHeaders,
        body: jsonEncode(<String, String>{'initData': initData}),
      ),
      timeout: apiTimeout,
      retries: 1,
    );
    return AuthResponse.fromJson(_decodeMap(response));
  }

  /// `GET /api/exercises/next` с необязательной категорией.
  Future<Exercise> nextExercise({
    TrainingCategory? category,
    String? focus,
    int? excludeId,
  }) async {
    final MockBackend? mock = _mock;
    if (mock != null) {
      return mock.nextExercise(
        category: category,
        focus: focus,
        excludeId: excludeId,
      );
    }

    final Uri base = _uri(epExercisesNext);
    final Map<String, String> query = <String, String>{
      if (category != null) 'category': category.apiValue,
      if (focus != null && focus.isNotEmpty) 'focus': focus,
      if (excludeId != null) 'exclude_id': '$excludeId',
    };
    final Uri uri = query.isEmpty ? base : base.replace(queryParameters: query);
    final http.Response response = await _send(
      () => _http.get(uri, headers: _authHeaders),
      timeout: apiTimeout,
      retries: 1,
    );
    return Exercise.fromJson(_decodeMap(response));
  }

  /// `POST /api/assess` с multipart-аудио.
  Future<Assessment> assess({
    required Uint8List audio,
    required int exerciseId,
  }) async {
    final MockBackend? mock = _mock;
    if (mock != null) {
      return mock.assess(audio: audio, exerciseId: exerciseId);
    }

    final http.MultipartRequest request =
        http.MultipartRequest('POST', _uri(epAssess))
          ..headers.addAll(_authHeaders)
          ..fields['exercise_id'] = '$exerciseId'
          ..files.add(
            http.MultipartFile.fromBytes(
              'audio',
              audio,
              filename: recordingFileName,
              contentType: MediaType.parse(recordingMimeType),
            ),
          );

    final http.Response response = await _send(() async {
      final http.StreamedResponse streamed = await _http.send(request);
      return http.Response.fromStream(streamed);
    }, timeout: assessTimeout);
    return Assessment.fromJson(_decodeMap(response));
  }

  /// `GET /api/v1/history` — последние попытки.
  Future<HistoryResponse> history({int limit = 20}) async {
    final MockBackend? mock = _mock;
    if (mock != null) {
      return mock.history(limit: limit);
    }

    final Uri uri = _uri(epHistory)
        .replace(queryParameters: <String, String>{'limit': '$limit'});
    final http.Response response = await _send(
      () => _http.get(uri, headers: _authHeaders),
      timeout: apiTimeout,
      retries: 1,
    );
    return HistoryResponse.fromJson(_decodeMap(response));
  }

  /// `GET /api/progress`.
  Future<Progress> progress() async {
    final MockBackend? mock = _mock;
    if (mock != null) {
      return mock.progress();
    }

    final http.Response response = await _send(
      () => _http.get(_uri(epProgress), headers: _authHeaders),
      timeout: apiTimeout,
      retries: 1,
    );
    return Progress.fromJson(_decodeMap(response));
  }

  Map<String, String> get _authHeaders => <String, String>{
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Map<String, String> get _jsonHeaders => <String, String>{
    ..._authHeaders,
    'Content-Type': 'application/json; charset=utf-8',
  };

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<http.Response> _send(
    Future<http.Response> Function() send, {
    required Duration timeout,
    int retries = 0,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final http.Response response = await send().timeout(timeout);

        if (response.statusCode >= 500 && attempt < retries) {
          await Future<void>.delayed(retryDelay);
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw _exceptionFor(response);
        }
        return response;
      } on ApiException {
        rethrow;
      } on TimeoutException catch (error) {
        lastError = error;
        if (attempt < retries) {
          await Future<void>.delayed(retryDelay);
          continue;
        }
        throw const ApiException(
          userMessage: 'Сервер долго не отвечает. Попробуйте ещё раз.',
          isTimeout: true,
        );
      } catch (error) {
        lastError = error;
        if (attempt < retries) {
          await Future<void>.delayed(retryDelay);
          continue;
        }
        throw ApiException(
          userMessage: 'Нет связи с сервером. Проверьте интернет.',
          isNetwork: true,
          serverDetail: error.toString(),
        );
      }
    }

    throw ApiException(
      userMessage: 'Нет связи с сервером. Проверьте интернет.',
      isNetwork: true,
      serverDetail: lastError?.toString(),
    );
  }

  ApiException _exceptionFor(http.Response response) {
    final String? detail = _detailFrom(response);
    final String message = switch (response.statusCode) {
      400 => 'Не удалось выполнить запрос. Попробуйте ещё раз.',
      401 => 'Не удалось подтвердить аккаунт. Откройте приложение заново.',
      403 => 'Доступ запрещён.',
      404 => 'Данные не найдены.',
      422 => 'Сервер не принял данные. Попробуйте ещё раз.',
      429 => 'Слишком много попыток. Подождите немного.',
      500 => 'На сервере произошла ошибка. Попробуйте позже.',
      502 || 503 || 504 => 'Сервис анализа речи сейчас недоступен. Попробуйте ещё раз через минуту.',
      _ => 'Не удалось получить ответ от сервера.',
    };

    return ApiException(
      statusCode: response.statusCode,
      userMessage: message,
      serverDetail: detail,
    );
  }

  String? _detailFrom(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }
    try {
      final Object? body = jsonDecode(
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );
      if (body is Map<Object?, Object?>) {
        final Object? detail = body['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Map<String, Object?> _decodeMap(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      throw const ApiException(
        userMessage: 'Сервер вернул пустой ответ. Попробуйте ещё раз.',
      );
    }
    try {
      final Object? body = jsonDecode(
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );
      if (body is Map<Object?, Object?>) {
        return body.cast<String, Object?>();
      }
    } on FormatException {
      // Ниже отдаём единое понятное сообщение.
    }
    throw const ApiException(
      userMessage: 'Сервер вернул неожиданный ответ. Попробуйте ещё раз.',
    );
  }

  static String _normalize(String value) {
    final String trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
