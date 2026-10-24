import 'package:flutter/material.dart';

import 'package:mini_app/models/assessment.dart';
import 'package:mini_app/models/exercise.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/theme/score_style.dart';
import 'package:mini_app/widgets/page_scaffold.dart';
import 'package:mini_app/widgets/phoneme_chip.dart';
import 'package:mini_app/widgets/score_badge.dart';

/// Что сделать после просмотра результата.
enum ResultAction { retry, next }

/// Экран результата: общая оценка, звуки и советы.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.exercise,
    required this.assessment,
  });

  final Exercise exercise;
  final Assessment assessment;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, int>> entries = assessment.phonemeEntries(
      exercise.phonemes,
    );
    final List<String> problematic = assessment.problematic;
    final String kind = exercise.kindTitle;

    return PageScaffold(
      title: 'Результат',
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: <Widget>[
                Text(
                  '$kind «${exercise.text}»',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 14),
                Center(child: ScoreBadge(score: assessment.score)),
                const SizedBox(height: 18),
                Text(
                  ScoreStyle.feedback(assessment.score),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 24),
                if (assessment.words.length > 1)
                  _WordsCard(words: assessment.words)
                else
                  _SoundCard(entries: entries, assessment: assessment),
                const SizedBox(height: 16),
                if (problematic.isEmpty)
                  const _SuccessCard()
                else
                  _AdviceCard(problematic: problematic),
              ],
            ),
          ),
          _ResultBottomBar(
            onRetry: () => Navigator.of(context).pop(ResultAction.retry),
            onNext: () => Navigator.of(context).pop(ResultAction.next),
          ),
        ],
      ),
    );
  }
}

class _WordsCard extends StatelessWidget {
  const _WordsCard({required this.words});

  final List<WordAssessment> words;

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.record_voice_over_rounded,
                size: 22,
                color: AppColors.primaryDark,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'По словам',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Проверили звуки в каждом слове. Красная рамка — звук стоит '
            'потренировать.',
            style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < words.length; index++) ...<Widget>[
            _WordResultTile(word: words[index]),
            if (index < words.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _WordResultTile extends StatelessWidget {
  const _WordResultTile({required this.word});

  final WordAssessment word;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundTop,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  word.text,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ScoreStyle.softColor(word.score),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${word.score}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ScoreStyle.color(word.score),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (word.phonemeEntries.isEmpty)
            const Text(
              'Сервис не вернул звуки для этого слова.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: word.phonemeEntries
                  .map(
                    (MapEntry<String, int> entry) => PhonemeChip(
                      phoneme: entry.key,
                      score: entry.value,
                      isProblematic: word.isProblematic(entry.key),
                      dense: true,
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _SoundCard extends StatelessWidget {
  const _SoundCard({required this.entries, required this.assessment});

  final List<MapEntry<String, int>> entries;
  final Assessment assessment;

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.graphic_eq_rounded,
                  size: 21,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Звуки',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Text(
              'Сервис не вернул разбивку по звукам. Общая оценка уже учтена.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.muted,
              ),
            )
          else ...<Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: entries
                  .map(
                    (MapEntry<String, int> entry) => PhonemeChip(
                      phoneme: entry.key,
                      score: entry.value,
                      isProblematic: assessment.isProblematic(entry.key),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            const Text(
              'Балл и цвет показывают, как получился каждый звук. '
              'Красная рамка — звук стоит потренировать.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.problematic});

  final List<String> problematic;

  @override
  Widget build(BuildContext context) {
    final List<String> shown = problematic.take(3).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.tips_and_updates_outlined,
                size: 22,
                color: AppColors.warning,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Что улучшить',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < shown.length; index++) ...<Widget>[
            _AdviceRow(phoneme: shown[index]),
            if (index < shown.length - 1) const SizedBox(height: 12),
          ],
          if (problematic.length > shown.length) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'И ещё ${problematic.length - shown.length} '
              '${_soundsLabel(problematic.length - shown.length)} — '
              'их тоже стоит повторить.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _soundsLabel(int count) {
    if (count == 1) {
      return 'звук';
    }
    if (count >= 2 && count <= 4) {
      return 'звука';
    }
    return 'звуков';
  }
}

class _AdviceRow extends StatelessWidget {
  const _AdviceRow({required this.phoneme});

  final String phoneme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              phoneme,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.warning,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Звук $phoneme',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ScoreStyle.adviceFor(phoneme),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.check_circle_rounded, size: 24, color: AppColors.success),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Все звуки получились хорошо',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Так держать! Попробуйте следующее упражнение.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
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

class _ResultBottomBar extends StatelessWidget {
  const _ResultBottomBar({required this.onRetry, required this.onNext});

  final VoidCallback onRetry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: _ResultActions(onRetry: onRetry, onNext: onNext),
        ),
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({required this.onRetry, required this.onNext});

  final VoidCallback onRetry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget retry = OutlinedButton.icon(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          icon: const Icon(Icons.replay_rounded, size: 20),
          label: const Text('Ещё раз'),
        );
        final Widget next = FilledButton.icon(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          label: const Text('Дальше'),
        );

        if (constraints.maxWidth < 330) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[retry, const SizedBox(height: 12), next],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: retry),
            const SizedBox(width: 12),
            Expanded(child: next),
          ],
        );
      },
    );
  }
}
