import 'package:flutter/material.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/theme/score_style.dart';

/// Плашка звука: буква и, если есть, оценка.
class PhonemeChip extends StatelessWidget {
  const PhonemeChip({
    super.key,
    required this.phoneme,
    this.score,
    this.isProblematic = false,
    this.dense = false,
  });

  final String phoneme;
  final int? score;
  final bool isProblematic;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final int? value = score;
    final Color foreground = value == null
        ? AppColors.ink
        : ScoreStyle.color(value);
    final Color background = value == null
        ? AppColors.surface
        : ScoreStyle.softColor(value);
    final Color border = value == null
        ? AppColors.outline
        : ScoreStyle.color(value).withValues(alpha: 0.45);

    final String semanticsLabel = value == null
        ? 'Звук $phoneme'
        : 'Звук $phoneme, $value из 100${isProblematic ? ', требует внимания' : ''}';

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 12,
            vertical: dense ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(dense ? 12 : 14),
            border: Border.all(
              color: isProblematic ? ScoreStyle.color(value ?? 0) : border,
              width: isProblematic ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                phoneme,
                style: TextStyle(
                  fontSize: dense ? 17 : 19,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  color: foreground,
                ),
              ),
              if (value != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: dense ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    color: foreground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
