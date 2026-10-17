import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mini_app/theme/app_theme.dart';

/// Анимированная «волна» голоса во время записи.
class SoundWave extends StatefulWidget {
  const SoundWave({
    super.key,
    this.active = true,
    this.color = AppColors.danger,
    this.width = 132,
    this.height = 36,
  });

  final bool active;
  final Color color;
  final double width;
  final double height;

  @override
  State<SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<SoundWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SoundWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat();
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _WavePainter(
              progress: _controller.value,
              color: widget.color,
              active: widget.active,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.progress,
    required this.color,
    required this.active,
  });

  final double progress;
  final Color color;
  final bool active;

  static const int _bars = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;

    final double step = size.width / (_bars + 1);
    final double centerY = size.height / 2;

    for (var index = 0; index < _bars; index++) {
      final double phase = progress * 2 * math.pi + index * 0.85;
      final double factor = active
          ? 0.28 + 0.72 * ((math.sin(phase) + 1) / 2)
          : 0.22 + 0.1 * index;
      final double height = size.height * factor.clamp(0.15, 1);
      final double x = step * (index + 1);
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.active != active;
  }
}
