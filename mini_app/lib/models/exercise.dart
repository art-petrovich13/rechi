import 'package:mini_app/models/json_readers.dart';

/// Упражнение: слово или фраза и их звуки.
class Exercise {
  const Exercise({
    required this.id,
    required this.text,
    required this.phonemes,
    required this.difficulty,
  });

  factory Exercise.fromJson(Map<String, Object?> json) {
    return Exercise(
      id: readInt(json['id']),
      text: readString(json['text']).trim(),
      phonemes: readStringList(json['phonemes']),
      difficulty: readInt(json['difficulty'], fallback: 1).clamp(1, 3),
    );
  }

  final int id;
  final String text;
  final List<String> phonemes;
  final int difficulty;

  /// Слово или фраза заглавными буквами для карточки упражнения.
  String get upperText => text.toUpperCase();

  /// Упражнение состоит из нескольких слов.
  bool get isPhrase => text.trim().contains(RegExp(r'\s+'));

  /// Подпись типа упражнения для интерфейса.
  String get kindLabel => isPhrase ? 'фраза' : 'слово';
}
