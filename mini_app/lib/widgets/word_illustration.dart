import 'package:flutter/material.dart';
import 'package:mini_app/theme/app_theme.dart';

/// Крупная иллюстрация к слову (эмодзи в мягком круге).
class WordIllustration extends StatelessWidget {
  const WordIllustration({super.key, required this.text, this.size = 148});

  final String text;
  final double size;

  static const Map<String, String> _emojiByWord = <String, String>{
    'рыба': '🐟',
    'рак': '🦀',
    'рука': '✋',
    'шар': '🎈',
    'шапка': '🧢',
    'лиса': '🦊',
    'ложка': '🥄',
    'сыр': '🧀',
    'сова': '🦉',
    'роза': '🌹',
    'лампа': '💡',
    'мышка': '🐭',
    'щука': '🐟',
    'чашка': '☕',
    'ракета': '🚀',
    'мяч': '⚽',
    'кот': '🐈',
    'дом': '🏠',
    'юла': '🌀',
    'ёлка': '🌲',
    'сок': '🧃',
    'сумка': '👜',
    'шуба': '🧥',
    'лук': '🧅',
    'лодка': '🚤',
  };

  String get _emoji {
    final String normalized = text.trim().toLowerCase();
    final String firstWord = normalized.split(RegExp(r'\s+')).first;
    return _emojiByWord[normalized] ?? _emojiByWord[firstWord] ?? '🗣️';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Иллюстрация к слову $text',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.primarySoft,
              AppColors.accentSoft.withValues(alpha: 0.85),
            ],
          ),
          border: Border.all(color: AppColors.surface, width: 4),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                _emoji,
                style: TextStyle(fontSize: size * 0.48, height: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
