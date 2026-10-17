import 'package:flutter/material.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/theme/score_style.dart';

/// Большой круг с оценкой 0–100.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score, this.size = 176});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color = ScoreStyle.color(score);
    final Color softColor = ScoreStyle.softColor(score);
    final double ringSize = size - 24;

    return Semantics(
      label: 'Оценка $score из 100',
      container: true,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: 0.14),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double value, Widget? child) {
                    return SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: size * 0.065,
                        strokeCap: StrokeCap.round,
                        color: color,
                        backgroundColor: softColor,
                      ),
                    );
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: size * 0.3,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'из 100',
                      style: TextStyle(
                        fontSize: size * 0.08,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
