import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mini_app/core/constants.dart';
import 'package:mini_app/core/object_url.dart';
import 'package:record/record.dart';

/// Ошибка записи или получения аудио.
class RecordingException implements Exception {
  const RecordingException(this.message);

  final String message;

  @override
  String toString() => 'RecordingException: $message';
}

/// Готовая запись: байты для отправки и адрес для прослушивания.
class Recording {
  Recording({required this.bytes, this.url, this.duration = Duration.zero});

  final Uint8List bytes;

  /// `blob:` на web, путь к файлу на мобильных; null — слушать нечего.
  final String? url;
  final Duration duration;

  bool _released = false;

  Recording withDuration(Duration value) {
    final Recording copy = Recording(bytes: bytes, url: url, duration: value);
    _released = true;
    return copy;
  }

  /// Освобождает адрес записи. Повторный вызов безопасен.
  void release() {
    final String? value = url;
    if (_released || value == null) {
      return;
    }
    _released = true;
    revokeObjectUrl(value);
  }
}

/// Рекордер, которым управляет [RecordingController].
abstract interface class AudioRecorderBackend {
  Duration get elapsed;
  Future<bool> ensurePermission();
  Future<void> start();
  Future<Recording?> stop();
  Future<void> cancel();
  void dispose();
}

/// Запись WAV 16 кГц / моно через пакет `record`.
///
/// На web `stop()` возвращает blob URL; байты читаются HTTP-запросом.
/// `dart:io` не используется, поэтому сервис собирается под web.
class AudioRecorderService implements AudioRecorderBackend {
  AudioRecorderService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final AudioRecorder _recorder = AudioRecorder();
  final http.Client _http;

  static const Duration _permissionTimeout = Duration(seconds: 15);
  static const Duration _startTimeout = Duration(seconds: 15);

  bool _isRecording = false;
  DateTime? _startedAt;

  bool get isRecording => _isRecording;

  @override
  Duration get elapsed {
    final DateTime? startedAt = _startedAt;
    if (startedAt == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(startedAt);
  }

  /// Проверяет и при необходимости запрашивает доступ к микрофону.
  @override
  Future<bool> ensurePermission() async {
    try {
      return await _recorder.hasPermission().timeout(_permissionTimeout);
    } on TimeoutException {
      debugPrint('Microphone permission timed out');
      return false;
    } catch (error) {
      debugPrint('Microphone permission failed: $error');
      return false;
    }
  }

  /// Начинает запись в WAV.
  @override
  Future<void> start() async {
    if (_isRecording) {
      return;
    }
    try {
      await _recorder
          .start(
            const RecordConfig(
              encoder: AudioEncoder.wav,
              sampleRate: recordingSampleRate,
              numChannels: recordingChannels,
            ),
            path: recordingFileName,
          )
          .timeout(_startTimeout);
      _isRecording = true;
      _startedAt = DateTime.now();
    } on TimeoutException {
      debugPrint('Recording start timed out');
      throw const RecordingException(
        'Браузер не ответил. Разрешите доступ к микрофону и попробуйте ещё раз.',
      );
    } catch (error) {
      debugPrint('Recording start failed: $error');
      throw const RecordingException(
        'Не удалось начать запись. Проверьте доступ к микрофону.',
      );
    }
  }

  /// Останавливает запись и возвращает WAV-байты и адрес для прослушивания.
  @override
  Future<Recording?> stop() async {
    if (!_isRecording) {
      return null;
    }

    _isRecording = false;
    _startedAt = null;

    try {
      final String? blobUrl = await _recorder.stop();
      if (blobUrl == null || blobUrl.isEmpty) {
        return null;
      }

      final http.Response response = await _http
          .get(Uri.parse(blobUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        revokeObjectUrl(blobUrl);
        throw const RecordingException(
          'Не удалось получить запись. Попробуйте ещё раз.',
        );
      }

      final Uint8List bytes = response.bodyBytes;
      if (bytes.length < 44) {
        revokeObjectUrl(blobUrl);
        throw const RecordingException('Запись получилась слишком короткой.');
      }
      return Recording(bytes: bytes, url: blobUrl);
    } on RecordingException {
      rethrow;
    } catch (error) {
      debugPrint('Recording stop failed: $error');
      throw const RecordingException(
        'Не удалось сохранить запись. Попробуйте ещё раз.',
      );
    }
  }

  /// Отменяет запись и освобождает микрофон.
  @override
  Future<void> cancel() async {
    _isRecording = false;
    _startedAt = null;
    try {
      await _recorder.cancel();
    } catch (error) {
      debugPrint('Recording cancel failed: $error');
    }
  }

  /// Освобождает ресурсы.
  @override
  void dispose() {
    _isRecording = false;
    _startedAt = null;
    unawaited(_recorder.dispose());
    _http.close();
  }
}
