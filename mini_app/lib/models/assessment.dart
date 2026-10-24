import 'package:mini_app/core/constants.dart';
import 'package:mini_app/models/json_readers.dart';

/// Результат одного слова внутри записи.
class WordAssessment {
  const WordAssessment({
    required this.text,
    required this.score,
    required this.phonemeScores,
  });

  factory WordAssessment.fromJson(Map<String, Object?> json) {
    return WordAssessment(
      text: readString(json['text']).trim(),
      score: readInt(json['score']).clamp(0, 100),
      phonemeScores: readIntMap(json['phoneme_scores']),
    );
  }

  final String text;
  final int score;
  final Map<String, int> phonemeScores;

  List<MapEntry<String, int>> get phonemeEntries =>
      phonemeScores.entries.toList(growable: false);

  bool isProblematic(String phoneme) =>
      (phonemeScores[phoneme] ?? 100) < problemScoreThreshold;
}

/// Результат проверки произношения.
class Assessment {
  const Assessment({
    required this.score,
    required this.phonemeScores,
    required this.problematic,
    this.words = const <WordAssessment>[],
  });

  factory Assessment.fromJson(Map<String, Object?> json) {
    final Map<String, int> scores = readIntMap(json['phoneme_scores']);
    final List<String> problematic = readStringList(json['problematic'])
        .where(scores.containsKey)
        .toList(growable: false);
    final List<WordAssessment> words = <WordAssessment>[];
    final Object? rawWords = json['words'];
    if (rawWords is List) {
      for (final Object? item in rawWords) {
        if (item is Map) {
          words.add(WordAssessment.fromJson(item.cast<String, Object?>()));
        }
      }
    }

    return Assessment(
      score: readInt(json['score']).clamp(0, 100),
      phonemeScores: scores,
      problematic: problematic,
      words: words,
    );
  }

  final int score;
  final Map<String, int> phonemeScores;
  final List<String> problematic;
  final List<WordAssessment> words;

  /// Звуки в порядке упражнения, затем остальные из ответа.
  List<MapEntry<String, int>> phonemeEntries(List<String> order) {
    final List<MapEntry<String, int>> result = <MapEntry<String, int>>[];
    final Set<String> used = <String>{};
    for (final String phoneme in order) {
      final int? score = phonemeScores[phoneme];
      if (score != null && used.add(phoneme)) {
        result.add(MapEntry<String, int>(phoneme, score));
      }
    }
    for (final MapEntry<String, int> entry in phonemeScores.entries) {
      if (used.add(entry.key)) {
        result.add(entry);
      }
    }
    return result;
  }

  bool isProblematic(String phoneme) => problematic.contains(phoneme);
}
