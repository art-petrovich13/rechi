import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mini_app/core/audio_recorder.dart';
import 'package:mini_app/core/constants.dart';

/// Этап записи. Переходы только такие:
///
/// idle → starting → recording → stopping → recorded
///                ↘ micDenied / failed       ↘ tooShort / failed
enum RecordingPhase {
  idle,
  starting,
  recording,
  stopping,
  recorded,
  tooShort,
  micDenied,
  failed,
}

/// Состояние записи для экрана упражнения.
///
/// Вынесено из виджета, чтобы переходы были явными и проверялись тестами,
/// а на мобильных платформах можно было подставить другой рекордер.
class RecordingController extends ChangeNotifier {
  RecordingController({
    required this._recorder,
    this._tick = const Duration(milliseconds: 100),
  });

  final AudioRecorderBackend _recorder;
  final Duration _tick;

  RecordingPhase _phase = RecordingPhase.idle;
  Duration _elapsed = Duration.zero;
  Recording? _recording;
  String? _error;
  bool _autoStopped = false;
  Timer? _timer;
  bool _disposed = false;

  RecordingPhase get phase => _phase;
  Duration get elapsed => _elapsed;
  Recording? get recording => _recording;
  String? get error => _error;

  /// Запись остановилась сама на лимите.
  bool get autoStopped => _autoStopped;

  bool get isRecording => _phase == RecordingPhase.recording;
  bool get isBusy =>
      _phase == RecordingPhase.starting || _phase == RecordingPhase.stopping;
  bool get hasRecording => _recording != null;

  /// Нажатие на кнопку микрофона.
  Future<void> toggle() {
    if (isRecording) {
      return stop();
    }
    return start();
  }

  Future<void> start() async {
    if (isBusy || isRecording) {
      return;
    }
    _discardRecording();
    _set(RecordingPhase.starting, elapsed: Duration.zero);

    final bool allowed = await _recorder.ensurePermission();
    if (_disposed) {
      return;
    }
    if (!allowed) {
      _set(RecordingPhase.micDenied);
      return;
    }

    try {
      await _recorder.start();
    } on RecordingException catch (error) {
      _fail(error.message);
      return;
    }
    if (_disposed) {
      unawaited(_recorder.cancel());
      return;
    }
    _autoStopped = false;
    _set(RecordingPhase.recording);
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  Future<void> stop({bool auto = false}) async {
    if (!isRecording) {
      return;
    }
    _timer?.cancel();
    final Duration duration = _recorder.elapsed;
    _autoStopped = auto;
    _set(RecordingPhase.stopping, elapsed: duration);

    try {
      final Recording? recording = await _recorder.stop();
      if (_disposed) {
        recording?.release();
        return;
      }
      if (recording == null || duration < minRecordingDuration) {
        recording?.release();
        _set(RecordingPhase.tooShort);
        return;
      }
      _recording = recording.withDuration(duration);
      _set(RecordingPhase.recorded);
    } on RecordingException catch (error) {
      _fail(error.message);
    }
  }

  /// Сбрасывает запись, чтобы записать заново.
  Future<void> reset() async {
    _timer?.cancel();
    if (isRecording) {
      await _recorder.cancel();
    }
    _discardRecording();
    _error = null;
    _set(RecordingPhase.idle, elapsed: Duration.zero);
  }

  /// Сервер не принял запись: нужна новая, с понятной причиной.
  void reject(String message) {
    _discardRecording();
    _fail(message);
  }

  /// Подставная запись для демо-режима без микрофона.
  void useDemoRecording() {
    _discardRecording();
    _recording = Recording(
      bytes: Uint8List.fromList(List<int>.filled(32000, 0)),
      duration: const Duration(seconds: 1),
    );
    _error = null;
    _set(RecordingPhase.recorded, elapsed: const Duration(seconds: 1));
  }

  void _onTick() {
    if (_disposed || !isRecording) {
      return;
    }
    _elapsed = _recorder.elapsed;
    notifyListeners();
    if (_elapsed >= const Duration(seconds: maxRecordingSeconds)) {
      unawaited(stop(auto: true));
    }
  }

  void _fail(String message) {
    _error = message;
    _set(RecordingPhase.failed);
  }

  void _discardRecording() {
    _recording?.release();
    _recording = null;
  }

  void _set(RecordingPhase phase, {Duration? elapsed}) {
    if (_disposed) {
      return;
    }
    _phase = phase;
    if (elapsed != null) {
      _elapsed = elapsed;
    }
    if (phase != RecordingPhase.failed) {
      _error = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _discardRecording();
    _recorder.dispose();
    super.dispose();
  }
}
