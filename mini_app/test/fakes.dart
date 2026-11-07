import 'dart:typed_data';

import 'package:mini_app/core/audio_recorder.dart';
import 'package:mini_app/core/exercise_audio.dart';

/// Рекордер без микрофона: длительность задаётся тестом.
class FakeRecorder implements AudioRecorderBackend {
  bool allowed = true;
  Duration fakeElapsed = const Duration(seconds: 2);
  int starts = 0;
  bool released = false;

  @override
  Duration get elapsed => fakeElapsed;

  @override
  Future<bool> ensurePermission() async => allowed;

  @override
  Future<void> start() async => starts++;

  @override
  Future<Recording?> stop() async {
    return Recording(
      bytes: Uint8List.fromList(List<int>.filled(64, 1)),
      url: 'blob:fake',
    );
  }

  @override
  Future<void> cancel() async {}

  @override
  void dispose() => released = true;
}

/// Звук без плагинов: образец «доступен», ничего не играет.
class FakeExerciseAudio extends ExerciseAudio {
  final List<String> spoken = <String>[];

  @override
  Future<bool> prepareSpeech() async => true;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> playRecording(String url) async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}
