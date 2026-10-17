import 'package:flutter/material.dart';
import 'package:mini_app/theme/app_theme.dart';

/// Логотип «Речи»: скруглённый квадрат с волной звука.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64, this.showShadow = true});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primaryBright, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: showShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: size * 0.32,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: Center(
        child: ExcludeSemantics(
          child: CustomPaint(
            size: Size(size * 0.56, size * 0.56),
            painter: const _SoundWavePainter(),
          ),
        ),
      ),
    );
  }
}

class _SoundWavePainter extends CustomPainter {
  const _SoundWavePainter();

  static const List<double> _heights = <double>[0.36, 0.66, 1, 0.55, 0.3];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round;

    final double step =
        (size.width - paint.strokeWidth) / (_heights.length - 1);
    for (var index = 0; index < _heights.length; index++) {
      final double x = paint.strokeWidth / 2 + step * index;
      final double height = size.height * _heights[index];
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoundWavePainter oldDelegate) => false;
}
