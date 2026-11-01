import 'package:flutter/material.dart';
import 'package:mini_app/theme/app_theme.dart';

/// Цвета, подписи и советы для оценки результата.
abstract final class ScoreStyle {
  /// Цвет оценки: красный < 50, жёлтый 50–75, зелёный > 75.
  static Color color(int score) {
    if (score > 75) {
      return AppColors.success;
    }
    if (score >= 50) {
      return AppColors.warning;
    }
    return AppColors.danger;
  }

  /// Мягкий фон для плашки с оценкой.
  static Color softColor(int score) {
    if (score > 75) {
      return AppColors.successSoft;
    }
    if (score >= 50) {
      return AppColors.warningSoft;
    }
    return AppColors.dangerSoft;
  }

  /// Короткая реакция на результат.
  static String feedback(int score) {
    if (score > 85) {
      return 'Отлично! Очень чисто и уверенно.';
    }
    if (score > 75) {
      return 'Хорошо! Ещё немного — и будет отлично.';
    }
    if (score >= 50) {
      return 'Неплохо. Давай поработаем над сложными звуками.';
    }
    return 'Пока не получилось. Попробуй ещё раз чуть медленнее.';
  }

  /// Совет по артикуляции для проблемного звука.
  static String adviceFor(String phoneme) {
    return switch (phoneme.toUpperCase()) {
      'Р' => 'Подними кончик языка к верху и добавь лёгкую вибрацию.',
      'Ш' => 'Округли губы и подними язык «чашечкой» к верху.',
      'Ж' => 'Как «Ш», но звонко: подключи голос.',
      'Л' => 'Прижми кончик языка к верхним зубам.',
      'С' => 'Улыбнись и спрячь язык за нижние зубы.',
      'З' => 'Как «С», но звонко: подключи голос.',
      'Ц' => 'Короткий «С», сразу за ним «Т».',
      'Ч' => 'Короткий мягкий «Ш» с лёгким «Т».',
      'Щ' => 'Долгий мягкий «Ш».',
      'К' => 'Короткий звук в глубине рта, без нажима.',
      'Г' => 'Как «К», но звонко.',
      'Х' => 'Лёгкий выдох, будто греешь ладони.',
      _ => 'Скажи звук медленно и чётко, потом повтори упражнение целиком.',
    };
  }
}
