import 'package:flutter/material.dart';
import 'package:mini_app/core/auth_service.dart';
import 'package:mini_app/core/progress_service.dart';
import 'package:mini_app/models/user.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/widgets/app_logo.dart';
import 'package:mini_app/widgets/primary_button.dart';
import 'package:provider/provider.dart';

/// Каркас экранов первого входа.
class _OnboardingFrame extends StatelessWidget {
  const _OnboardingFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Center(child: AppLogo(size: 64)),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _runSafely(
  BuildContext context,
  Future<void> Function() action,
) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  try {
    await action();
  } catch (error) {
    debugPrint('Profile update failed: $error');
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Не удалось сохранить. Проверьте интернет и повторите.'),
      ),
    );
  }
}

/// Согласие на обработку данных перед первой тренировкой.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agreed = false;
  bool _saving = false;

  Future<void> _accept() async {
    setState(() => _saving = true);
    await _runSafely(context, context.read<AuthService>().acceptConsent);
    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingFrame(
      title: 'Перед началом',
      children: <Widget>[
        const _Fact(
          icon: Icons.mic_rounded,
          text:
              'Запись голоса отправляется на проверку в сервис оценки '
              'произношения SpeechSuper. Мы её не сохраняем.',
        ),
        const _Fact(
          icon: Icons.insights_rounded,
          text:
              'Мы храним ваше имя и номер в Telegram и результаты занятий: '
              'баллы по звукам и словам, темп и ритм.',
        ),
        const _Fact(
          icon: Icons.delete_outline_rounded,
          text:
              'Все данные можно удалить в настройках в любой момент. '
              'Восстановить их после удаления нельзя.',
        ),
        const _Fact(
          icon: Icons.medical_services_outlined,
          text:
              'Это тренажёр, а не медицинское изделие. Он не заменяет '
              'занятия со специалистом.',
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _agreed,
          onChanged: (bool? value) => setState(() => _agreed = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Я согласен(на) на обработку этих данных. Если занимается '
            'ребёнок, я его родитель или законный представитель.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Продолжить',
          icon: Icons.arrow_forward_rounded,
          onPressed: _agreed && !_saving ? _accept : null,
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 24, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Выбор, кто занимается: от этого зависят упражнения и тон текстов.
class AudienceScreen extends StatelessWidget {
  const AudienceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = context.read<AuthService>();
    return _OnboardingFrame(
      title: 'Кто будет заниматься?',
      children: <Widget>[
        AudienceOption(
          audience: UserAudience.adult,
          onSelected: () =>
              _runSafely(context, () => auth.setAudience(UserAudience.adult)),
        ),
        const SizedBox(height: 12),
        AudienceOption(
          audience: UserAudience.child,
          onSelected: () =>
              _runSafely(context, () => auth.setAudience(UserAudience.child)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Выбор можно поменять в настройках.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Крупная карточка выбора аудитории.
class AudienceOption extends StatelessWidget {
  const AudienceOption({
    super.key,
    required this.audience,
    required this.onSelected,
    this.selected = false,
  });

  final UserAudience audience;
  final VoidCallback onSelected;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final (String title, String text, IconData icon) = switch (audience) {
      UserAudience.adult => (
        'Взрослый',
        'Восстановление речи, например после инсульта',
        Icons.person_rounded,
      ),
      UserAudience.child => (
        'Ребёнок',
        'Занятия вместе с родителем: простые слова и игры',
        Icons.child_care_rounded,
      ),
    };
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected ? AppColors.primaryDark : AppColors.outline,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 36, color: AppColors.primaryDark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Показывается после удаления данных.
class DataDeletedScreen extends StatelessWidget {
  const DataDeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _OnboardingFrame(
      title: 'Данные удалены',
      children: <Widget>[
        const Text(
          'Мы удалили ваш профиль и все результаты занятий.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, height: 1.45, color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Начать заново',
          icon: Icons.refresh_rounded,
          onPressed: () {
            context.read<ProgressService>().reset();
            context.read<AuthService>().signIn();
          },
        ),
      ],
    );
  }
}
