import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/theme/score_style.dart';

void main() {
  group('ScoreStyle.color', () {
    test('красный для оценки ниже 50', () {
      expect(ScoreStyle.color(0), AppColors.danger);
      expect(ScoreStyle.color(49), AppColors.danger);
    });

    test('жёлтый для 50–75', () {
      expect(ScoreStyle.color(50), AppColors.warning);
      expect(ScoreStyle.color(75), AppColors.warning);
    });

    test('зелёный для оценки выше 75', () {
      expect(ScoreStyle.color(76), AppColors.success);
      expect(ScoreStyle.color(100), AppColors.success);
    });
  });

  group('ScoreStyle.feedback', () {
    test('даёт разную реакцию на разные диапазоны', () {
      expect(ScoreStyle.feedback(90), contains('Отлично'));
      expect(ScoreStyle.feedback(80), contains('Хорошо'));
      expect(ScoreStyle.feedback(60), contains('Неплохо'));
      expect(ScoreStyle.feedback(30), contains('Попробуй'));
    });
  });

  group('ScoreStyle.adviceFor', () {
    test('знает сложные звуки', () {
      expect(ScoreStyle.adviceFor('Р'), isNotEmpty);
      expect(ScoreStyle.adviceFor('ш'), isNotEmpty);
      expect(ScoreStyle.adviceFor('Ю'), isNotEmpty);
    });
  });
}
