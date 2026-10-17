import 'package:mini_app/models/json_readers.dart';

/// Результат проверки произношения.
class Assessment {
  const Assessment({
    required this.score,
    required this.phonemeScores,
    required this.problematic,
  });

  factory Assessment.fromJson(Map<String, Object?> json) {
    final Map<String, int> scores = readIntMap(json['phoneme_scores']);
    final List<String> problematic = readStringList(
      json['problematic'],
    ).where(scores.containsKey).toList(growable: false);

    return Assessment(
      score: readInt(json['score']).clamp(0, 100),
      phonemeScores: scores,
      problematic: problematic,
    );
  }

  final int score;
  final Map<String, int> phonemeScores;
  final List<String> problematic;

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
