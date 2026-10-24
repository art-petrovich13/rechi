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
    this.onTap,
  });

  final String phoneme;
  final int? score;
  final bool isProblematic;
  final bool dense;
  final VoidCallback? onTap;

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

    final Widget chip = Container(
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
    );

    if (onTap == null) {
      return Semantics(
        label: semanticsLabel,
        container: true,
        child: ExcludeSemantics(child: chip),
      );
    }

    return Semantics(
      label: '$semanticsLabel. Потренировать звук',
      button: true,
      container: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(dense ? 12 : 14),
          child: chip,
        ),
      ),
    );
  }
}
