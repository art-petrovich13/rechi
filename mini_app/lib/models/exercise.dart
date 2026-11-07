import 'package:mini_app/models/json_readers.dart';
import 'package:mini_app/models/training_category.dart';

/// Почему сервер выбрал упражнение.
enum SelectionReason {
  repeat('repeat'),
  similar('similar'),
  newExercise('new'),
  review('review');

  const SelectionReason(this.apiValue);

  final String apiValue;

  static SelectionReason? fromApi(Object? value) {
    for (final SelectionReason reason in SelectionReason.values) {
      if (reason.apiValue == value) {
        return reason;
      }
    }
    return null;
  }

  /// Подпись для пользователя; для нового упражнения не нужна.
  String? get label => switch (this) {
    SelectionReason.repeat => 'Повторим: в прошлый раз было трудно',
    SelectionReason.similar => 'Похожие звуки на те, что стоит потренировать',
    SelectionReason.review => 'Закрепляем пройденное',
    SelectionReason.newExercise => null,
  };
}

/// Упражнение: слово или фраза и их звуки.
class Exercise {
  const Exercise({
    required this.id,
    required this.text,
    required this.phonemes,
    required this.difficulty,
    this.category = TrainingCategory.word,
    this.reason,
  });

  factory Exercise.fromJson(Map<String, Object?> json) {
    return Exercise(
      id: readInt(json['id']),
      text: readString(json['text']).trim(),
      phonemes: readStringList(json['phonemes']),
      difficulty: readInt(json['difficulty'], fallback: 1).clamp(1, 3),
      category: TrainingCategory.fromApi(json['category']),
      reason: SelectionReason.fromApi(json['reason']),
    );
  }

  final int id;
  final String text;
  final List<String> phonemes;
  final int difficulty;
  final TrainingCategory category;
  final SelectionReason? reason;

  /// Слово или фраза заглавными буквами для карточки упражнения.
  String get upperText => text.toUpperCase();

  /// Упражнение состоит из нескольких слов.
  bool get isPhrase =>
      category != TrainingCategory.word || text.trim().contains(RegExp(r'\s+'));

  /// Название категории для заголовка результата.
  String get kindTitle => category.title;
}
