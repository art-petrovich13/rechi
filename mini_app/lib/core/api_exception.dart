/// Ошибка API с человеческим сообщением для интерфейса.
class ApiException implements Exception {
  const ApiException({
    required this.userMessage,
    this.statusCode,
    this.serverDetail,
    this.code,
    this.isNetwork = false,
    this.isTimeout = false,
  });

  /// Текст, который можно показать пользователю.
  final String userMessage;

  /// HTTP-статус, если ответ пришёл от сервера.
  final int? statusCode;

  /// Технический ответ сервера (для логов).
  final String? serverDetail;

  /// Машиночитаемый код ошибки от backend.
  final String? code;

  /// Не удалось установить соединение.
  final bool isNetwork;

  /// Запрос не уложился в таймаут.
  final bool isTimeout;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  /// Эту запись нет смысла отправлять ещё раз: нужна новая.
  bool get requiresNewRecording => code?.startsWith('audio_') ?? false;

  /// Лимит попыток: повтор сразу не поможет.
  bool get isRateLimited => statusCode == 429;

  bool get isServiceUnavailable =>
      statusCode == 502 || statusCode == 503 || statusCode == 504;

  @override
  String toString() {
    final String code = statusCode == null ? '' : ' [$statusCode]';
    final String detail = serverDetail == null ? '' : ' ($serverDetail)';
    return 'ApiException$code: $userMessage$detail';
  }
}
