import 'package:flutter/material.dart';
import 'package:mini_app/theme/app_theme.dart';

/// Общий каркас внутренних экранов.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.showBack = true,
    this.padding = AppSpacing.pagePadding,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showBack;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null && actions == null && !showBack
          ? null
          : AppBar(
              title: title == null ? null : Text(title!),
              actions: actions,
              automaticallyImplyLeading: showBack,
            ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
