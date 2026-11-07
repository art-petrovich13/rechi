import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Звук на экране упражнения: образец произношения и своя запись.
///
/// Образец озвучивает синтез речи устройства. Если русского голоса нет,
/// кнопка образца не показывается.
class ExerciseAudio {
  ExerciseAudio({AudioPlayer? player, FlutterTts? tts})
    : _playerOverride = player,
      _ttsOverride = tts;

  final AudioPlayer? _playerOverride;
  final FlutterTts? _ttsOverride;
  AudioPlayer? _player;
  FlutterTts? _tts;
  bool _speechReady = false;

  bool get canSpeak => _speechReady;

  /// Готовит синтез речи; возвращает, есть ли русский голос.
  Future<bool> prepareSpeech() async {
    try {
      final FlutterTts tts = _tts ??= _ttsOverride ?? FlutterTts();
      final Object? available = await tts.isLanguageAvailable('ru-RU');
      if (available != true) {
        return _speechReady = false;
      }
      await tts.setLanguage('ru-RU');
      // Медленнее обычного: образец должен быть разборчивым.
      await tts.setSpeechRate(kIsWeb ? 0.8 : 0.4);
      return _speechReady = true;
    } catch (error) {
      debugPrint('Speech synthesis unavailable: $error');
      return _speechReady = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_speechReady) {
      return;
    }
    await stop();
    try {
      await _tts?.speak(text);
    } catch (error) {
      debugPrint('Speak failed: $error');
    }
  }

  /// Проигрывает свою запись: `blob:` на web или путь к файлу.
  Future<void> playRecording(String url) async {
    await stop();
    try {
      final AudioPlayer player = _player ??= _playerOverride ?? AudioPlayer();
      final bool remote = url.startsWith('blob:') || url.startsWith('http');
      await player.play(remote ? UrlSource(url) : DeviceFileSource(url));
    } catch (error) {
      debugPrint('Playback failed: $error');
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
      await _tts?.stop();
    } catch (error) {
      debugPrint('Audio stop failed: $error');
    }
  }

  void dispose() {
    _player?.dispose();
    _tts?.stop();
  }
}
