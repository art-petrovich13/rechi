import 'package:flutter/material.dart';
import 'package:mini_app/core/api_client.dart';
import 'package:mini_app/core/api_exception.dart';
import 'package:mini_app/models/assessment.dart';
import 'package:mini_app/models/history.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/theme/score_style.dart';
import 'package:mini_app/widgets/error_view.dart';
import 'package:mini_app/widgets/page_scaffold.dart';
import 'package:mini_app/widgets/phoneme_chip.dart';
import 'package:provider/provider.dart';

/// История последних попыток с разбором по словам.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final ApiClient _api;
  late Future<HistoryResponse> _future;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiClient>();
    _future = _api.history();
  }

  void _retry() {
    setState(() => _future = _api.history());
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'История',
      padding: EdgeInsets.zero,
      child: FutureBuilder<HistoryResponse>(
        future: _future,
        builder:
            (BuildContext context, AsyncSnapshot<HistoryResponse> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final Object error = snapshot.error!;
                final String message = error is ApiException
                    ? error.userMessage
                    : 'Не удалось загрузить историю. Попробуйте ещё раз.';
                return Padding(
                  padding: AppSpacing.pagePadding,
                  child: ErrorView(
                    title: 'История недоступна',
                    message: message,
                    onRetry: _retry,
                  ),
                );
              }
              final HistoryResponse data =
                  snapshot.data ??
                  const HistoryResponse(attempts: <HistoryEntry>[]);
              if (data.attempts.isEmpty) {
                return const _EmptyHistory();
              }
              return RefreshIndicator(
                onRefresh: () async {
                  _retry();
                  await _future;
                },
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  itemCount: data.attempts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    return _HistoryCard(
                      entry: data.attempts[index],
                      initiallyExpanded: index == 0,
                    );
                  },
                ),
              );
            },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.initiallyExpanded});

  final HistoryEntry entry;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            entry.exerciseText,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${entry.category.label} · ${_formatDate(entry.createdAt)}',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          trailing: _ScorePill(score: entry.score),
          children: <Widget>[
            if (entry.words.isEmpty)
              const Text(
                'Разбор по словам появится после следующей тренировки.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              )
            else
              for (
                var index = 0;
                index < entry.words.length;
                index++
              ) ...<Widget>[
                _HistoryWordRow(word: entry.words[index]),
                if (index < entry.words.length - 1) const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year}, '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ScoreStyle.softColor(score),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: ScoreStyle.color(score),
        ),
      ),
    );
  }
}

class _HistoryWordRow extends StatelessWidget {
  const _HistoryWordRow({required this.word});

  final WordAssessment word;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundTop,
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '${word.score}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ScoreStyle.color(word.score),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (word.phonemeEntries.isEmpty)
            const Text(
              'Нет разбивки по звукам.',
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 40,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Пока нет попыток',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Начните тренировку — здесь появится история с разбором '
              'каждого слова и звука.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.45,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
