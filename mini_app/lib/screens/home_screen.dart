import 'package:flutter/material.dart';
import 'package:mini_app/core/auth_service.dart';
import 'package:mini_app/core/constants.dart';
import 'package:mini_app/core/progress_service.dart';
import 'package:mini_app/models/progress.dart';
import 'package:mini_app/screens/exercise_screen.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/widgets/app_logo.dart';
import 'package:mini_app/widgets/demo_badge.dart';
import 'package:mini_app/widgets/error_view.dart';
import 'package:mini_app/widgets/how_it_works_sheet.dart';
import 'package:mini_app/widgets/phoneme_chip.dart';
import 'package:mini_app/widgets/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Главный экран: приветствие, прогресс и старт тренировки.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _introKey = 'intro_seen';

  bool _introChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ProgressService>().load();
      _maybeShowIntro();
    });
  }

  Future<void> _maybeShowIntro() async {
    if (_introChecked) {
      return;
    }
    _introChecked = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_introKey) ?? false) {
        return;
      }
      if (!mounted) {
        return;
      }
      await showHowItWorksSheet(context);
      await prefs.setBool(_introKey, true);
    } catch (error) {
      debugPrint('Intro failed: $error');
    }
  }

  Future<void> _startTraining() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ExerciseScreen(),
      ),
    );
    if (!mounted) {
      return;
    }
    await context.read<ProgressService>().load(silent: true);
  }

  Future<void> _refresh() {
    return context.read<ProgressService>().load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final AuthService auth = context.watch<AuthService>();
    final ProgressService progress = context.watch<ProgressService>();
    final String name = auth.user?.displayName ?? '';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: <Widget>[
                  _HomeHeader(
                    isDemo: auth.isDemo,
                    onHelp: () => showHowItWorksSheet(context),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    name.isEmpty ? 'Привет!' : 'Привет, $name!',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Готовы потренировать речь? Это займёт 3–5 минут.',
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                  if (auth.isDemo) ...<Widget>[
                    const SizedBox(height: 14),
                    const _DemoBanner(),
                  ],
                  const SizedBox(height: 22),
                  _ProgressCard(progress: progress, onRetry: progress.load),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Начать тренировку',
                    icon: Icons.mic_rounded,
                    onPressed: _startTraining,
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      '3–5 минут в день',
                      style: TextStyle(fontSize: 14, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _TipCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.isDemo, required this.onHelp});

  final bool isDemo;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const AppLogo(size: 46),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                appName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 2),
              Text(
                appTagline,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (isDemo) ...<Widget>[const DemoBadge(), const SizedBox(width: 4)],
        IconButton(
          onPressed: onHelp,
          tooltip: 'Как заниматься',
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.science_outlined, size: 20, color: AppColors.primaryDark),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Демо-режим: упражнения и оценки тестовые.',
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.onRetry});

  final ProgressService progress;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Progress? data = progress.progress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outline),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 21,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Твой прогресс',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (progress.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (!progress.hasLoaded)
            const _ProgressSkeleton()
          else if (data == null)
            ErrorView(
              compact: true,
              message:
                  progress.errorMessage ?? 'Не удалось загрузить прогресс.',
              onRetry: onRetry,
            )
          else ...<Widget>[
            _ProgressContent(data: data),
            if (progress.errorMessage != null) ...<Widget>[
              const SizedBox(height: 14),
              ErrorView(
                compact: true,
                message: progress.errorMessage!,
                onRetry: onRetry,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.data});

  final Progress data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '${data.attemptsCount}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                height: 0.95,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _attemptsLabel(data.attemptsCount),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Слабые звуки',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Средние баллы по звукам за всё время',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        if (data.weakPhonemes.isEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                data.attemptsCount == 0
                    ? Icons.check_circle_outline_rounded
                    : Icons.verified_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.attemptsCount == 0
                      ? 'Пока нет результатов. После первой тренировки здесь '
                            'появятся звуки, над которыми стоит поработать.'
                      : 'Отличный прогресс: слабых звуков пока нет. '
                            'Продолжайте тренироваться.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.weakPhonemes
                .map(
                  (WeakPhoneme item) => PhonemeChip(
                    phoneme: item.phoneme,
                    score: item.avgScore,
                    dense: true,
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }

  static String _attemptsLabel(int count) {
    final int mod10 = count % 10;
    final int mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return 'попытка';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'попытки';
    }
    return 'попыток';
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 64,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF3F7),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 90,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF3F7),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF3F7),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        FractionallySizedBox(
          widthFactor: 0.7,
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF3F7),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 22,
            color: AppColors.primaryDark,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Совет',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Говорите в обычном темпе и не спешите. Короткая уверенная '
                  'запись лучше длинной и торопливой.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.ink,
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
