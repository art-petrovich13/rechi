import 'package:flutter/material.dart';
import 'package:mini_app/theme/app_theme.dart';

/// Мягкий градиентный фон приложения.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AppColors.backgroundTop,
                  AppColors.backgroundBottom,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -70,
          child: _Glow(
            size: 250,
            color: AppColors.primary.withValues(alpha: 0.06),
          ),
        ),
        Positioned(
          bottom: -110,
          left: -80,
          child: _Glow(
            size: 230,
            color: AppColors.accent.withValues(alpha: 0.05),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
