import 'package:flutter/material.dart';
import 'package:mini_app/theme/app_theme.dart';

/// Полноэкранный индикатор обработки записи.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, required this.message, this.hint});

  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Semantics(
        label: message,
        liveRegion: true,
        child: ColoredBox(
          color: AppColors.ink.withValues(alpha: 0.24),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if (hint != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            hint!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
