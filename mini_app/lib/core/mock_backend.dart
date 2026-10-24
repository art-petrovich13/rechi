import 'dart:math';
import 'dart:typed_data';

import 'package:mini_app/core/api_exception.dart';
import 'package:mini_app/core/constants.dart';
import 'package:mini_app/models/assessment.dart';
import 'package:mini_app/models/auth_response.dart';
import 'package:mini_app/models/exercise.dart';
import 'package:mini_app/models/history.dart';
import 'package:mini_app/models/progress.dart';
import 'package:mini_app/models/training_category.dart';
import 'package:mini_app/models/user.dart';

/// Демо-бэкенд для работы без сервера.
///
/// Повторяет контракт настоящего API, добавляет небольшие задержки
/// и правдоподобные оценки, чтобы можно было проверить весь флоу.
class MockBackend {
  MockBackend({
    Random? random,
    this.authDelay = const Duration(milliseconds: 250),
    this.nextDelay = const Duration(milliseconds: 400),
    this.assessDelay = const Duration(milliseconds: 1400),
    this.progressDelay = const Duration(milliseconds: 300),
  }) : _random = random ?? Random();

  final Random _random;
  final Duration authDelay;
  final Duration nextDelay;
  final Duration assessDelay;
  final Duration progressDelay;

  final List<_MockAttempt> _attempts = <_MockAttempt>[];
  int? _lastExerciseId;

  static const List<Exercise> _exercises = <Exercise>[
    Exercise(
      id: 1,
      text: 'рыба',
      phonemes: <String>['Р', 'Ы', 'Б', 'А'],
      difficulty: 2,
    ),
    Exercise(
      id: 2,
      text: 'рак',
      phonemes: <String>['Р', 'А', 'К'],
      difficulty: 1,
    ),
    Exercise(
      id: 3,
      text: 'рука',
      phonemes: <String>['Р', 'У', 'К', 'А'],
      difficulty: 2,
    ),
    Exercise(
      id: 4,
      text: 'шар',
      phonemes: <String>['Ш', 'А', 'Р'],
      difficulty: 1,
    ),
    Exercise(
      id: 5,
      text: 'шапка',
      phonemes: <String>['Ш', 'А', 'П', 'К', 'А'],
      difficulty: 2,
    ),
    Exercise(
      id: 6,
      text: 'лиса',
      phonemes: <String>['Л', 'И', 'С', 'А'],
      difficulty: 2,
    ),
    Exercise(
      id: 7,
      text: 'ложка',
      phonemes: <String>['Л', 'О', 'Ш', 'К', 'А'],
      difficulty: 2,
    ),
    Exercise(
      id: 8,
      text: 'сыр',
      phonemes: <String>['С', 'Ы', 'Р'],
      difficulty: 1,
    ),
    Exercise(
      id: 9,
      text: 'сова',
      phonemes: <String>['С', 'О', 'В', 'А'],
      difficulty: 2,
    ),
    Exercise(
      id: 10,
      text: 'роза',
      phonemes: <String>['Р', 'О', 'З', 'А'],
      difficulty: 2,
    ),
    Exercise(
      id: 11,
      text: 'лампа',
      phonemes: <String>['Л', 'А', 'М', 'П', 'А'],
      difficulty: 2,
    ),
    Exercise(
      id: 12,
      text: 'мышка',
      phonemes: <String>['М', 'Ы', 'Ш', 'К', 'А'],
      difficulty: 3,
    ),
    Exercise(
      id: 13,
      text: 'щука',
      phonemes: <String>['Щ', 'У', 'К', 'А'],
      difficulty: 3,
    ),
    Exercise(
      id: 14,
      text: 'чашка',
      phonemes: <String>['Ч', 'А', 'Ш', 'К', 'А'],
      difficulty: 3,
    ),
    Exercise(
      id: 15,
      text: 'ракета',
      phonemes: <String>['Р', 'А', 'К', 'Е', 'Т', 'А'],
      difficulty: 3,
    ),
    Exercise(
      id: 16,
      text: 'мама мыла раму',
      phonemes: <String>['М', 'А', 'Ы', 'Л', 'Р', 'У'],
      difficulty: 2,
      category: TrainingCategory.phrase,
    ),
    Exercise(
      id: 17,
      text: 'красная машина',
      phonemes: <String>['К', 'Р', 'А', 'С', 'Н', 'Я', 'М', 'Ш', 'И'],
      difficulty: 2,
      category: TrainingCategory.phrase,
    ),
    Exercise(
      id: 18,
      text: 'я вижу большую рыбу',
      phonemes: <String>[
        'Я',
        'В',
        'И',
        'Ж',
        'У',
        'Б',
        'О',
        'Л',
        'Ш',
        'А',
        'Ю',
        'Р',
        'Ы',
      ],
      difficulty: 2,
      category: TrainingCategory.sentence,
    ),
    Exercise(
      id: 19,
      text: 'мама купила красную шапку',
      phonemes: <String>[
        'М',
        'А',
        'К',
        'У',
        'П',
        'И',
        'Л',
        'Р',
        'С',
        'Н',
        'Ю',
        'Ш',
      ],
      difficulty: 3,
      category: TrainingCategory.sentence,
    ),
  ];

  static const Set<String> _hardPhonemes = <String>{
    'Р',
    'Ш',
    'Л',
    'С',
    'Щ',
    'Ч',
    'Ж',
    'З',
  };

  /// Демо-пользователь.
  Future<AuthResponse> auth(String initData) async {
    await Future<void>.delayed(authDelay);
    return const AuthResponse(
      token: 'demo-token',
      user: User(id: 1, firstName: 'Иван'),
    );
  }

  /// Случайное упражнение категории, не повторяющее предыдущее.
  Future<Exercise> nextExercise({
    TrainingCategory? category,
    String? focus,
  }) async {
    await Future<void>.delayed(nextDelay);
    final String? normalizedFocus = focus?.trim().toUpperCase();
    final List<Exercise> pool = _exercises
        .where(
          (Exercise exercise) =>
              (category == null || exercise.category == category) &&
              (normalizedFocus == null ||
                  normalizedFocus.isEmpty ||
                  exercise.phonemes.contains(normalizedFocus)),
        )
        .toList(growable: false);
    if (pool.isEmpty) {
      throw const ApiException(
        statusCode: 404,
        userMessage: 'В этой категории пока нет упражнений.',
      );
    }
    if (pool.length == 1) {
      _lastExerciseId = pool.first.id;
      return pool.first;
    }

    Exercise candidate = pool[_random.nextInt(pool.length)];
    var guard = 0;
    while (candidate.id == _lastExerciseId && guard < 10) {
      candidate = pool[_random.nextInt(pool.length)];
      guard++;
    }
    _lastExerciseId = candidate.id;
    return candidate;
  }

  /// Правдоподобная оценка: один «сложный» звук ниже остальных.
  Future<Assessment> assess({
    required Uint8List audio,
    required int exerciseId,
  }) async {
    await Future<void>.delayed(assessDelay);

    final Exercise? exercise = _findExercise(exerciseId);
    if (exercise == null) {
      throw const ApiException(
        statusCode: 404,
        userMessage: 'Упражнение не найдено.',
      );
    }
    if (exercise.phonemes.isEmpty) {
      throw const ApiException(
        statusCode: 502,
        userMessage: 'В упражнении нет звуков для проверки.',
      );
    }

    final bool goodAttempt = _random.nextDouble() < 0.3;
    final List<String> hard = exercise.phonemes
        .where(_hardPhonemes.contains)
        .toList(growable: false);
    final String weak = hard.isNotEmpty
        ? hard[_random.nextInt(hard.length)]
        : exercise.phonemes[_random.nextInt(exercise.phonemes.length)];

    final Map<String, int> scores = <String, int>{};
    for (final String phoneme in exercise.phonemes) {
      if (phoneme == weak) {
        scores[phoneme] = goodAttempt
            ? 62 + _random.nextInt(13)
            : 36 + _random.nextInt(25);
      } else {
        scores[phoneme] = goodAttempt
            ? 84 + _random.nextInt(16)
            : 72 + _random.nextInt(27);
      }
    }

    final int overall = scores.isEmpty
        ? 0
        : (scores.values.reduce((int a, int b) => a + b) / scores.length)
              .round();
    final List<String> problematic =
        scores.entries
            .where(
              (MapEntry<String, int> entry) =>
                  entry.value < problemScoreThreshold,
            )
            .map((MapEntry<String, int> entry) => entry.key)
            .toList(growable: false)
          ..sort((String a, String b) => scores[a]!.compareTo(scores[b]!));

    final List<WordAssessment> words = exercise.isPhrase
        ? _wordAssessments(exercise, scores, overall)
        : <WordAssessment>[
            WordAssessment(
              text: exercise.text,
              score: overall,
              phonemeScores: scores,
            ),
          ];
    final bool hasMetrics = exercise.isPhrase;
    final int metricBase = (overall + 6).clamp(0, 100);
    final Assessment assessment = Assessment(
      score: overall,
      phonemeScores: scores,
      problematic: problematic,
      words: words,
      fluency: hasMetrics ? metricBase : null,
      rhythm: hasMetrics ? (overall + 2).clamp(0, 100) : null,
      pronunciation: hasMetrics ? overall : null,
      duration: hasMetrics ? 2.8 : null,
    );
    _attempts.add(
      _MockAttempt(
        exercise: exercise,
        assessment: assessment,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    return assessment;
  }

  /// История попыток текущей демо-сессии.
  Future<HistoryResponse> history({int limit = 20}) async {
    await Future<void>.delayed(progressDelay);
    final List<HistoryEntry> entries = <HistoryEntry>[];
    for (var index = 0; index < _attempts.length && index < limit; index++) {
      final _MockAttempt attempt = _attempts[_attempts.length - 1 - index];
      entries.add(
        HistoryEntry(
          id: _attempts.length - index,
          exerciseId: attempt.exercise.id,
          exerciseText: attempt.exercise.text,
          category: attempt.exercise.category,
          score: attempt.assessment.score,
          phonemeScores: attempt.assessment.phonemeScores,
          problematic: attempt.assessment.problematic,
          words: attempt.assessment.words,
          createdAt: attempt.createdAt,
        ),
      );
    }
    return HistoryResponse(attempts: entries);
  }

  List<WordAssessment> _wordAssessments(
    Exercise exercise,
    Map<String, int> scores,
    int overall,
  ) {
    final List<WordAssessment> result = <WordAssessment>[];
    for (final String word in exercise.text.split(RegExp(r'\s+'))) {
      final List<String> letters = word
          .toUpperCase()
          .replaceAll(RegExp(r'[^А-ЯЁ]'), '')
          .split('');
      final List<String> unique = <String>[];
      for (final String letter in letters) {
        if (!unique.contains(letter)) {
          unique.add(letter);
        }
      }
      result.add(
        WordAssessment(
          text: word,
          score: overall,
          phonemeScores: <String, int>{
            for (final String phoneme in unique) phoneme: scores[phoneme] ?? 80,
          },
        ),
      );
    }
    return result;
  }

  /// Прогресс, собранный из попыток текущей сессии.
  /// Прогресс, собранный из попыток текущей сессии.
  Future<Progress> progress() async {
    await Future<void>.delayed(progressDelay);

    final Map<String, List<int>> byPhoneme = <String, List<int>>{};
    for (final _MockAttempt attempt in _attempts) {
      for (final MapEntry<String, int> entry
          in attempt.assessment.phonemeScores.entries) {
        byPhoneme.putIfAbsent(entry.key, () => <int>[]).add(entry.value);
      }
    }

    final List<WeakPhoneme> weak =
        byPhoneme.entries
            .map((MapEntry<String, List<int>> entry) {
              final int sum = entry.value.reduce((int a, int b) => a + b);
              return WeakPhoneme(
                phoneme: entry.key,
                avgScore: (sum / entry.value.length).round(),
              );
            })
            .toList(growable: false)
          ..sort(
            (WeakPhoneme a, WeakPhoneme b) => a.avgScore.compareTo(b.avgScore),
          );

    return Progress(
      attemptsCount: _attempts.length,
      weakPhonemes: weak.take(5).toList(growable: false),
    );
  }

  /// Сброс состояния для тестов.
  void reset() {
    _attempts.clear();
    _lastExerciseId = null;
  }

  Exercise? _findExercise(int id) {
    for (final Exercise exercise in _exercises) {
      if (exercise.id == id) {
        return exercise;
      }
    }
    return null;
  }
}

class _MockAttempt {
  const _MockAttempt({
    required this.exercise,
    required this.assessment,
    required this.createdAt,
  });

  final Exercise exercise;
  final Assessment assessment;
  final DateTime createdAt;
}
