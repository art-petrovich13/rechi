import 'package:flutter/material.dart';

/// Основная кнопка действия с иконкой и состоянием загрузки.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget? leading = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
        : (icon == null ? null : Icon(icon, size: 22));

    final Widget button = leading == null
        ? FilledButton(
            onPressed: isLoading ? null : onPressed,
            child: Text(label),
          )
        : FilledButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: leading,
            label: Text(label),
          );

    if (!expand) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}
