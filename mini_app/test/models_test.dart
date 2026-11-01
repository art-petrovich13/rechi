import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app/models/assessment.dart';
import 'package:mini_app/models/auth_response.dart';
import 'package:mini_app/models/exercise.dart';
import 'package:mini_app/models/history.dart';
import 'package:mini_app/models/progress.dart';
import 'package:mini_app/models/training_category.dart';
import 'package:mini_app/models/user.dart';

void main() {
  group('User.fromJson', () {
    test('читает snake_case и обрезает имя', () {
      final User user = User.fromJson(<String, Object?>{
        'id': 7,
        'first_name': '  Иван ',
      });

      expect(user.id, 7);
      expect(user.firstName, 'Иван');
    });

    test('не падает без имени', () {
      final User user = User.fromJson(<String, Object?>{'id': '12'});

      expect(user.id, 12);
      expect(user.firstName, isEmpty);
    });
  });

  group('AuthResponse.fromJson', () {
    test('читает токен и пользователя', () {
      final AuthResponse response = AuthResponse.fromJson(<String, Object?>{
        'token': 'jwt',
        'user': <String, Object?>{'id': 1, 'first_name': 'Иван'},
      });

      expect(response.token, 'jwt');
      expect(response.user.firstName, 'Иван');
    });
  });

  group('Exercise.fromJson', () {
    test('нормализует звуки и ограничивает сложность', () {
      final Exercise exercise = Exercise.fromJson(<String, Object?>{
        'id': 5,
        'text': ' рыба ',
        'phonemes': <String>['р', 'ы', 'б', 'а'],
        'difficulty': 9,
      });

      expect(exercise.text, 'рыба');
      expect(exercise.phonemes, <String>['Р', 'Ы', 'Б', 'А']);
      expect(exercise.difficulty, 3);
      expect(exercise.upperText, 'РЫБА');
    });

    test('распознаёт фразу', () {
      final Exercise exercise = Exercise.fromJson(<String, Object?>{
        'id': 15,
        'text': 'мама мыла раму',
        'phonemes': <String>['М', 'А', 'Ы', 'Л', 'Р', 'У'],
        'difficulty': 2,
        'category': 'phrase',
      });

      expect(exercise.isPhrase, isTrue);
      expect(exercise.category, TrainingCategory.phrase);
      expect(exercise.kindLabel, 'фраза');
      expect(exercise.upperText, 'МАМА МЫЛА РАМУ');
    });

    test('переживает отсутствие полей', () {
      final Exercise exercise = Exercise.fromJson(<String, Object?>{});

      expect(exercise.id, 0);
      expect(exercise.text, isEmpty);
      expect(exercise.phonemes, isEmpty);
      expect(exercise.difficulty, 1);
    });
  });

  group('Assessment.fromJson', () {
    test('читает оценки и проблемные звуки', () {
      final Assessment assessment = Assessment.fromJson(<String, Object?>{
        'score': 78,
        'phoneme_scores': <String, Object?>{
          'Р': 45,
          'Ы': 88,
          'Б': 90,
          'А': '95',
        },
        'problematic': <String>['р', 'Ч'],
      });

      expect(assessment.score, 78);
      expect(assessment.phonemeScores['Р'], 45);
      expect(assessment.phonemeScores['А'], 95);
      expect(assessment.problematic, <String>['Р']);
      expect(assessment.isProblematic('Р'), isTrue);
    });

    test('сохраняет порядок звуков упражнения', () {
      final Assessment assessment = Assessment.fromJson(<String, Object?>{
        'score': 80,
        'phoneme_scores': <String, Object?>{'Б': 90, 'Р': 45, 'А': 95, 'Ы': 88},
        'problematic': <String>['Р'],
      });

      final List<MapEntry<String, int>> entries = assessment.phonemeEntries(
        <String>['Р', 'Ы', 'Б', 'А'],
      );

      expect(entries.map((MapEntry<String, int> entry) => entry.key), <String>[
        'Р',
        'Ы',
        'Б',
        'А',
      ]);
    });

    test('читает разбор по словам', () {
      final Assessment assessment = Assessment.fromJson(<String, Object?>{
        'score': 78,
        'phoneme_scores': <String, Object?>{'М': 60, 'А': 80},
        'problematic': <String>['М'],
        'words': <Map<String, Object?>>[
          <String, Object?>{
            'text': 'мама',
            'score': 90,
            'phoneme_scores': <String, Object?>{'М': 90, 'А': 92},
          },
          <String, Object?>{
            'text': 'мыла',
            'score': 64,
            'phoneme_scores': <String, Object?>{'М': 59, 'Ы': 80},
          },
        ],
      });

      expect(assessment.words.length, 2);
      expect(assessment.words.first.text, 'мама');
      expect(assessment.words.first.score, 90);
      expect(assessment.words.last.isProblematic('М'), isTrue);
      expect(assessment.words.last.phonemeEntries.length, 2);
    });

    test('читает метрики беглости и ритма', () {
      final Assessment assessment = Assessment.fromJson(<String, Object?>{
        'score': 82,
        'phoneme_scores': <String, Object?>{'Я': 90},
        'problematic': <String>[],
        'fluency': 74.6,
        'rhythm': '81',
        'pronunciation': 90,
        'speed': 186,
        'duration': 3.0,
      });

      expect(assessment.fluency, 75);
      expect(assessment.rhythm, 81);
      expect(assessment.pronunciation, 90);
      expect(assessment.speed, 186);
      expect(assessment.duration, 3.0);
      expect(assessment.hasMetrics, isTrue);
    });

    test('ограничивает оценку диапазоном 0–100', () {
      final Assessment assessment = Assessment.fromJson(<String, Object?>{
        'score': 140,
        'phoneme_scores': <String, Object?>{'Р': -10},
        'problematic': <String>[],
      });

      expect(assessment.score, 100);
      expect(assessment.phonemeScores['Р'], -10);
    });
  });

  group('HistoryEntry.fromJson', () {
    test('читает попытку с разбором по словам', () {
      final HistoryEntry entry = HistoryEntry.fromJson(<String, Object?>{
        'id': 7,
        'exercise_id': 43,
        'exercise_text': 'я вижу большую рыбу',
        'category': 'sentence',
        'score': 82,
        'phoneme_scores': <String, Object?>{'Я': 90, 'В': 80},
        'problematic': <String>['В'],
        'words': <Map<String, Object?>>[
          <String, Object?>{
            'text': 'я',
            'score': 90,
            'phoneme_scores': <String, Object?>{'Я': 90},
          },
        ],
        'created_at': '2026-10-24T12:00:00+00:00',
      });

      expect(entry.exerciseText, 'я вижу большую рыбу');
      expect(entry.category, TrainingCategory.sentence);
      expect(entry.words.single.text, 'я');
      expect(entry.createdAt.isUtc, isTrue);
    });
  });

  group('Progress.fromJson', () {
    test('сортирует слабые звуки и оставляет пять', () {
      final Progress progress = Progress.fromJson(<String, Object?>{
        'attempts_count': 42,
        'weak_phonemes': <Map<String, Object?>>[
          <String, Object?>{'phoneme': 'ш', 'avg_score': 61},
          <String, Object?>{'phoneme': 'р', 'avg_score': 52},
          <String, Object?>{'phoneme': 'с', 'avg_score': 70},
          <String, Object?>{'phoneme': 'л', 'avg_score': 65},
          <String, Object?>{'phoneme': 'з', 'avg_score': 68},
          <String, Object?>{'phoneme': 'ц', 'avg_score': 72},
        ],
      });

      expect(progress.attemptsCount, 42);
      expect(progress.weakPhonemes.length, 5);
      expect(progress.weakPhonemes.first.phoneme, 'Р');
      expect(progress.weakPhonemes.first.avgScore, 52);
      expect(progress.isEmpty, isFalse);
    });

    test('возвращает пустой прогресс без попыток', () {
      final Progress progress = Progress.fromJson(<String, Object?>{
        'attempts_count': 0,
        'weak_phonemes': <Object?>[],
      });

      expect(progress.isEmpty, isTrue);
      expect(progress.weakPhonemes, isEmpty);
    });
  });
}
