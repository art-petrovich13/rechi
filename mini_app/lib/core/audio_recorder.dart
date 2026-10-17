import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mini_app/core/constants.dart';
import 'package:record/record.dart';

/// Ошибка записи или получения аудио.
class RecordingException implements Exception {
  const RecordingException(this.message);

  final String message;

  @override
  String toString() => 'RecordingException: $message';
}

/// Запись WAV 16 кГц / моно через пакет `record`.
///
/// На web `stop()` возвращает blob URL; байты читаются HTTP-запросом.
/// `dart:io` не используется, поэтому сервис собирается под web.
class AudioRecorderService {
  AudioRecorderService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final AudioRecorder _recorder = AudioRecorder();
  final http.Client _http;

  static const Duration _permissionTimeout = Duration(seconds: 15);
  static const Duration _startTimeout = Duration(seconds: 15);

  bool _isRecording = false;
  DateTime? _startedAt;

  bool get isRecording => _isRecording;

  Duration get elapsed {
    final DateTime? startedAt = _startedAt;
    if (startedAt == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(startedAt);
  }

  /// Проверяет и при необходимости запрашивает доступ к микрофону.
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

  /// Останавливает запись и возвращает WAV-байты.
  Future<Uint8List?> stop() async {
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
        throw const RecordingException(
          'Не удалось получить запись. Попробуйте ещё раз.',
        );
      }

      final Uint8List bytes = response.bodyBytes;
      if (bytes.length < 44) {
        throw const RecordingException('Запись получилась слишком короткой.');
      }
      return bytes;
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
  void dispose() {
    _isRecording = false;
    _startedAt = null;
    unawaited(_recorder.dispose());
    _http.close();
  }
}
