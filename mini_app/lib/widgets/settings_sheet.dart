import 'package:flutter/material.dart';
import 'package:mini_app/core/auth_service.dart';
import 'package:mini_app/models/user.dart';
import 'package:mini_app/screens/onboarding_screens.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// Настройки: кто занимается и удаление данных.
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  Future<void> _confirmDelete(BuildContext context) async {
    final AuthService auth = context.read<AuthService>();
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Удалить все данные?'),
        content: const Text(
          'Профиль, история и прогресс будут удалены навсегда. '
          'Восстановить их нельзя.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await auth.deleteAccount();
      navigator.popUntil((Route<dynamic> route) => route.isFirst);
    } catch (error) {
      debugPrint('Delete failed: $error');
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось удалить. Попробуйте позже.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService auth = context.watch<AuthService>();
    final UserAudience? current = auth.user?.audience;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Настройки', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          const Text(
            'Кто занимается',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final UserAudience audience in UserAudience.values) ...<Widget>[
            AudienceOption(
              audience: audience,
              selected: audience == current,
              onSelected: () => auth.setAudience(audience),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Удалить мои данные'),
          ),
        ],
      ),
    );
  }
}
