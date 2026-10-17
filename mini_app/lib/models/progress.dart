import 'package:mini_app/models/json_readers.dart';

/// Прогресс пользователя.
class Progress {
  const Progress({required this.attemptsCount, required this.weakPhonemes});

  factory Progress.fromJson(Map<String, Object?> json) {
    final Object? rawWeak = json['weak_phonemes'];
    final List<WeakPhoneme> weak = rawWeak is List<Object?>
        ? rawWeak
              .whereType<Map<Object?, Object?>>()
              .map(
                (Map<Object?, Object?> item) => WeakPhoneme.fromJson(
                  item.cast<String, Object?>(),
                ),
              )
              .where((WeakPhoneme item) => item.phoneme.isNotEmpty)
              .toList(growable: false)
        : const <WeakPhoneme>[];

    final List<WeakPhoneme> sorted = List<WeakPhoneme>.of(weak)
      ..sort(
        (WeakPhoneme a, WeakPhoneme b) => a.avgScore.compareTo(b.avgScore),
      );

    return Progress(
      attemptsCount: readInt(json['attempts_count']),
      weakPhonemes: sorted.take(5).toList(growable: false),
    );
  }

  static const Progress empty = Progress(
    attemptsCount: 0,
    weakPhonemes: <WeakPhoneme>[],
  );

  final int attemptsCount;
  final List<WeakPhoneme> weakPhonemes;

  bool get isEmpty => attemptsCount == 0;
}

/// Звук со средним баллом.
class WeakPhoneme {
  const WeakPhoneme({required this.phoneme, required this.avgScore});

  factory WeakPhoneme.fromJson(Map<String, Object?> json) {
    return WeakPhoneme(
      phoneme: readString(json['phoneme']).trim().toUpperCase(),
      avgScore: readInt(json['avg_score']).clamp(0, 100),
    );
  }

  final String phoneme;
  final int avgScore;
}
