import 'package:flutter/material.dart';

import 'package:mini_app/core/auth_service.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/widgets/app_logo.dart';
import 'package:mini_app/widgets/primary_button.dart';

/// Экран ошибки входа с повтором и демо-режимом.
class AuthErrorScreen extends StatelessWidget {
  const AuthErrorScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final _AuthErrorContent content = _contentFor(auth.errorKind);
    final String message = auth.errorMessage ?? content.message;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const AppLogo(size: 68),
                  const SizedBox(height: 26),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: content.softColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(content.icon, size: 34, color: content.color),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    content.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.45,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Попробовать снова',
                    icon: Icons.refresh_rounded,
                    onPressed: auth.signIn,
                  ),
                  if (auth.canUseDemo) ...<Widget>[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: auth.signInAsDemo,
                        icon: const Icon(Icons.science_outlined, size: 22),
                        label: const Text('Продолжить в демо-режиме'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    content.hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static _AuthErrorContent _contentFor(AuthErrorKind kind) {
    return switch (kind) {
      AuthErrorKind.noTelegram => const _AuthErrorContent(
        title: 'Откройте через Telegram',
        message:
            'Приложение работает внутри Telegram. Запустите бота '
            'и нажмите «Начать».',
        hint:
            'Если вы уже в Telegram, попробуйте закрыть и открыть '
            'Mini App заново.',
        icon: Icons.chat_bubble_outline_rounded,
        color: AppColors.primaryDark,
        softColor: AppColors.primarySoft,
      ),
      AuthErrorKind.network => const _AuthErrorContent(
        title: 'Нет связи с сервером',
        message: 'Проверьте интернет и попробуйте снова.',
        hint:
            'На мероприятии интернет может быть нестабильным — '
            'подождите пару секунд и повторите.',
        icon: Icons.wifi_off_rounded,
        color: AppColors.warning,
        softColor: AppColors.warningSoft,
      ),
      AuthErrorKind.unauthorized => const _AuthErrorContent(
        title: 'Не удалось войти',
        message: 'Сессия недействительна. Откройте приложение заново.',
        hint: 'Закройте Mini App и запустите её из чата с ботом.',
        icon: Icons.lock_outline_rounded,
        color: AppColors.danger,
        softColor: AppColors.dangerSoft,
      ),
      AuthErrorKind.none || AuthErrorKind.unknown => const _AuthErrorContent(
        title: 'Не получилось войти',
        message: 'Что-то пошло не так. Попробуйте ещё раз.',
        hint: 'Если ошибка повторяется, покажите её разработчику.',
        icon: Icons.error_outline_rounded,
        color: AppColors.danger,
        softColor: AppColors.dangerSoft,
      ),
    };
  }
}

class _AuthErrorContent {
  const _AuthErrorContent({
    required this.title,
    required this.message,
    required this.hint,
    required this.icon,
    required this.color,
    required this.softColor,
  });

  final String title;
  final String message;
  final String hint;
  final IconData icon;
  final Color color;
  final Color softColor;
}
