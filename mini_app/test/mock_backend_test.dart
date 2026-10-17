import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app/core/api_exception.dart';
import 'package:mini_app/core/mock_backend.dart';
import 'package:mini_app/models/assessment.dart';
import 'package:mini_app/models/auth_response.dart';
import 'package:mini_app/models/exercise.dart';
import 'package:mini_app/models/progress.dart';

MockBackend _backend() {
  return MockBackend(
    random: Random(7),
    authDelay: Duration.zero,
    nextDelay: Duration.zero,
    assessDelay: Duration.zero,
    progressDelay: Duration.zero,
  );
}

void main() {
  group('MockBackend', () {
    test('выдаёт демо-пользователя', () async {
      final AuthResponse response = await _backend().auth('');

      expect(response.token, isNotEmpty);
      expect(response.user.firstName, 'Иван');
    });

    test('не повторяет предыдущее упражнение', () async {
      final MockBackend backend = _backend();
      final Exercise first = await backend.nextExercise();
      final Exercise second = await backend.nextExercise();

      expect(second.id, isNot(first.id));
      expect(second.phonemes, isNotEmpty);
    });

    test('возвращает оценки в диапазоне 0–100', () async {
      final MockBackend backend = _backend();
      final Exercise exercise = await backend.nextExercise();

      final Assessment assessment = await backend.assess(
        audio: Uint8List(0),
        exerciseId: exercise.id,
      );

      expect(assessment.score, inInclusiveRange(0, 100));
      expect(
        assessment.phonemeScores.keys,
        containsAll(exercise.phonemes.toSet()),
      );
      for (final int score in assessment.phonemeScores.values) {
        expect(score, inInclusiveRange(0, 100));
      }
      for (final String phoneme in assessment.problematic) {
        expect(assessment.phonemeScores[phoneme], lessThan(60));
      }
    });

    test('накапливает прогресс по попыткам', () async {
      final MockBackend backend = _backend();
      final Exercise exercise = await backend.nextExercise();

      for (var i = 0; i < 3; i++) {
        await backend.assess(audio: Uint8List(0), exerciseId: exercise.id);
      }

      final Progress progress = await backend.progress();
      expect(progress.attemptsCount, 3);
      expect(progress.weakPhonemes, isNotEmpty);
      expect(progress.weakPhonemes.length, lessThanOrEqualTo(5));
      for (var i = 1; i < progress.weakPhonemes.length; i++) {
        expect(
          progress.weakPhonemes[i - 1].avgScore,
          lessThanOrEqualTo(progress.weakPhonemes[i].avgScore),
        );
      }
    });

    test('кидает 404 для неизвестного упражнения', () async {
      await expectLater(
        _backend().assess(audio: Uint8List(0), exerciseId: 999),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.statusCode,
            'status',
            404,
          ),
        ),
      );
    });
  });
}
