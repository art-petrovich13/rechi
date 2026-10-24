import 'package:mini_app/models/assessment.dart';
import 'package:mini_app/models/json_readers.dart';
import 'package:mini_app/models/training_category.dart';

/// Одна попытка в истории пользователя.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.exerciseId,
    required this.exerciseText,
    required this.category,
    required this.score,
    required this.phonemeScores,
    required this.problematic,
    required this.words,
    required this.createdAt,
  });

  factory HistoryEntry.fromJson(Map<String, Object?> json) {
    return HistoryEntry(
      id: readInt(json['id']),
      exerciseId: readInt(json['exercise_id']),
      exerciseText: readString(json['exercise_text']).trim(),
      category: TrainingCategory.fromApi(json['category']),
      score: readInt(json['score']).clamp(0, 100),
      phonemeScores: readIntMap(json['phoneme_scores']),
      problematic: readStringList(json['problematic']),
      words: readWordAssessments(json['words']),
      createdAt:
          DateTime.tryParse(readString(json['created_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final int id;
  final int exerciseId;
  final String exerciseText;
  final TrainingCategory category;
  final int score;
  final Map<String, int> phonemeScores;
  final List<String> problematic;
  final List<WordAssessment> words;
  final DateTime createdAt;

  String get kindTitle => category.title;
}

/// Ответ истории попыток.
class HistoryResponse {
  const HistoryResponse({required this.attempts});

  factory HistoryResponse.fromJson(Map<String, Object?> json) {
    final List<HistoryEntry> attempts = <HistoryEntry>[];
    final Object? raw = json['attempts'];
    if (raw is List) {
      for (final Object? item in raw) {
        if (item is Map) {
          attempts.add(HistoryEntry.fromJson(item.cast<String, Object?>()));
        }
      }
    }
    return HistoryResponse(attempts: attempts);
  }

  final List<HistoryEntry> attempts;
}
