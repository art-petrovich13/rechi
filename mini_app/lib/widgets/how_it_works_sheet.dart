import 'package:flutter/material.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/widgets/app_logo.dart';

/// Показывает инструкцию «Как заниматься».
Future<void> showHowItWorksSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => const _HowItWorksSheet(),
  );
}

class _HowItWorksSheet extends StatelessWidget {
  const _HowItWorksSheet();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                const AppLogo(size: 44, showShadow: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Как заниматься',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _Step(
              icon: Icons.visibility_rounded,
              title: '1. Посмотрите на задание',
              text:
                  'Прочитайте слово, фразу или предложение и их звуки. Можно повторять целиком '
                  'или по слогам — как удобнее.',
            ),
            const _Step(
              icon: Icons.mic_rounded,
              title: '2. Запишите голос',
              text:
                  'Нажмите на микрофон и говорите в обычном темпе. '
                  'Запись длится до 20 секунд.',
            ),
            const _Step(
              icon: Icons.insights_rounded,
              title: '3. Получите оценку',
              text:
                  'Мы покажем общий балл и подскажем, какие звуки '
                  'стоит потренировать.',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Аудио не сохраняется — оно уходит только на проверку.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Понятно'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
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
    );
  }
}
