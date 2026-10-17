import 'package:flutter/material.dart';

/// Цветовая палитра приложения.
///
/// Спокойная светлая тема с крупными контрастными элементами:
/// аудитория — дети и взрослые после инсульта.
abstract final class AppColors {
  static const Color backgroundTop = Color(0xFFF4F7FB);
  static const Color backgroundBottom = Color(0xFFE7F3EE);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFF1F7A6D);
  static const Color primaryDark = Color(0xFF155B52);
  static const Color primaryBright = Color(0xFF2E9C8A);
  static const Color primarySoft = Color(0xFFDDF1EC);

  static const Color accent = Color(0xFFF2A93B);
  static const Color accentSoft = Color(0xFFFFF1D9);

  static const Color ink = Color(0xFF172A3A);
  static const Color muted = Color(0xFF5A6A79);
  static const Color outline = Color(0xFFDCE6EE);
  static const Color outlineStrong = Color(0xFFC6D4DF);

  static const Color success = Color(0xFF237A4B);
  static const Color successSoft = Color(0xFFE5F4EA);
  static const Color warning = Color(0xFFA85F00);
  static const Color warningSoft = Color(0xFFFFF1DB);
  static const Color danger = Color(0xFFB3352A);
  static const Color dangerSoft = Color(0xFFFBE9E6);

  static const Color shadow = Color(0x14172A3A);
}

/// Отступы и ограничения размеров.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double maxContentWidth = 560;
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 8, 20, 28);
}

/// Светлая тема приложения.
abstract final class AppTheme {
  static ThemeData get light {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.accent,
          onSecondary: AppColors.ink,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          error: AppColors.danger,
          onError: Colors.white,
          outline: AppColors.outline,
          outlineVariant: AppColors.outline,
          surfaceContainerHighest: const Color(0xFFEEF4F7),
          surfaceTint: Colors.transparent,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: AppColors.surface,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w800,
          height: 1.0,
          letterSpacing: 1.5,
          color: AppColors.ink,
        ),
        displayMedium: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          height: 1.05,
          color: AppColors.ink,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.15,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: AppColors.ink,
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppColors.muted,
        ),
        labelLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: AppColors.ink,
        ),
        labelMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: AppColors.ink,
        ),
        labelSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: AppColors.muted,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 24),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
        iconTheme: IconThemeData(color: AppColors.ink, size: 26),
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE8EEF3),
          disabledForegroundColor: AppColors.muted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          foregroundColor: AppColors.primaryDark,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.outlineStrong, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySoft,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          fontSize: 16,
          height: 1.35,
          color: Colors.white,
        ),
        actionTextColor: AppColors.accent,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 17,
          height: 1.45,
          color: AppColors.ink,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.outlineStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.ink,
      ),
    );
  }
}
