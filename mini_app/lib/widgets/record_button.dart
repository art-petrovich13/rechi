import 'package:flutter/material.dart';
import 'package:mini_app/theme/app_theme.dart';

/// Большая круглая кнопка записи с пульсацией.
class RecordButton extends StatefulWidget {
  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
    this.enabled = true,
  });

  final bool isRecording;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isRecording) {
      _pulse.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulse.repeat();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool recording = widget.isRecording;
    final Color color = recording ? AppColors.danger : AppColors.primary;

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (recording)
            AnimatedBuilder(
              animation: _pulse,
              builder: (BuildContext context, Widget? child) {
                final double value = _pulse.value;
                return Container(
                  width: 108 + 44 * value,
                  height: 108 + 44 * value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.danger.withValues(
                      alpha: 0.18 * (1 - value),
                    ),
                    border: Border.all(
                      color: AppColors.danger.withValues(
                        alpha: 0.35 * (1 - value),
                      ),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          Semantics(
            button: true,
            enabled: widget.enabled,
            label: recording ? 'Остановить запись' : 'Начать запись',
            child: ExcludeSemantics(
              child: GestureDetector(
                onTap: widget.enabled ? widget.onPressed : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: recording
                          ? const <Color>[Color(0xFFE05B4F), AppColors.danger]
                          : const <Color>[
                              AppColors.primaryBright,
                              AppColors.primaryDark,
                            ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.enabled ? widget.onPressed : null,
                      child: Center(
                        child: Icon(
                          recording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 46,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
