import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mini_app/core/api_client.dart';
import 'package:mini_app/core/api_exception.dart';
import 'package:mini_app/core/audio_recorder.dart';
import 'package:mini_app/core/constants.dart';
import 'package:mini_app/core/exercise_audio.dart';
import 'package:mini_app/core/recording_controller.dart';
import 'package:mini_app/core/telegram_bridge.dart';
import 'package:mini_app/models/assessment.dart';
import 'package:mini_app/models/exercise.dart';
import 'package:mini_app/models/training_category.dart';
import 'package:mini_app/screens/result_screen.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/widgets/error_view.dart';
import 'package:mini_app/widgets/loading_overlay.dart';
import 'package:mini_app/widgets/page_scaffold.dart';
import 'package:mini_app/widgets/phoneme_chip.dart';
import 'package:mini_app/widgets/primary_button.dart';
import 'package:mini_app/widgets/record_button.dart';
import 'package:mini_app/widgets/sound_wave.dart';
import 'package:mini_app/widgets/word_illustration.dart';
import 'package:provider/provider.dart';

/// Экран упражнения: слово или фраза, запись WAV и отправка на проверку.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({
    super.key,
    required this.category,
    this.focus,
    this.recorder,
    this.audio,
  });

  final TrainingCategory category;
  final String? focus;

  /// Подмена рекордера и звука для тестов и других платформ.
  final AudioRecorderBackend? recorder;
  final ExerciseAudio? audio;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  static const List<String> _loadingMessages = <String>[
    'Слушаем запись…',
    'Сравниваем звуки…',
    'Считаем оценку…',
    'Почти готово…',
  ];

  late final ApiClient _api;
  late final TelegramBridge _telegram;
  late final RecordingController _recording;
  late final ExerciseAudio _audio;
  final ScrollController _scrollController = ScrollController();

  Exercise? _exercise;
  final List<int> _skippedIds = <int>[];
  bool _loading = true;
  String? _error;
  bool _notFound = false;
  bool _canSpeak = false;

  bool _sending = false;
  String? _sendError;
  String _loadingMessage = _loadingMessages.first;
  Timer? _messageTimer;
  int _messageIndex = 0;
  RecordingPhase _lastPhase = RecordingPhase.idle;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiClient>();
    _telegram = context.read<TelegramBridge>();
    _recording = RecordingController(
      recorder: widget.recorder ?? AudioRecorderService(),
    )..addListener(_onRecordingChanged);
    _audio = widget.audio ?? ExerciseAudio();
    unawaited(_prepareSpeech());
    _loadNext();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _telegram.setClosingConfirmation(enabled: false);
    _recording
      ..removeListener(_onRecordingChanged)
      ..dispose();
    _audio.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _prepareSpeech() async {
    final bool ready = await _audio.prepareSpeech();
    if (mounted) {
      setState(() => _canSpeak = ready);
    }
  }

  void _onRecordingChanged() {
    final RecordingPhase phase = _recording.phase;
    _syncClosingConfirmation();
    if (phase == _lastPhase) {
      return;
    }
    final RecordingPhase previous = _lastPhase;
    _lastPhase = phase;
    if (phase == RecordingPhase.recording) {
      unawaited(HapticFeedback.lightImpact());
    }
    if (phase == RecordingPhase.recorded &&
        previous == RecordingPhase.stopping) {
      _scrollToBottom();
      unawaited(HapticFeedback.mediumImpact());
      if (_recording.autoStopped) {
        _showSnack('Запись остановлена на $maxRecordingSeconds секундах.');
      }
    }
  }

  void _syncClosingConfirmation() {
    _telegram.setClosingConfirmation(
      enabled: _sending || _recording.isRecording || _recording.isBusy,
    );
  }

  Future<void> _loadNext({bool skip = false}) async {
    final int? currentId = _exercise?.id;
    if (skip && currentId != null && !_skippedIds.contains(currentId)) {
      _skippedIds.add(currentId);
      if (_skippedIds.length > maxSkippedExercises) {
        _skippedIds.removeAt(0);
      }
    }

    _messageTimer?.cancel();
    unawaited(_audio.stop());
    await _recording.reset();
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _notFound = false;
      _exercise = null;
      _sendError = null;
    });

    try {
      final Exercise exercise = await _fetchNext();
      if (!mounted) {
        return;
      }
      if (exercise.text.isEmpty || exercise.phonemes.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Упражнение пришло пустым. Попробуйте другое.';
        });
        return;
      }
      setState(() {
        _exercise = exercise;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.userMessage;
        _notFound = error.isNotFound;
      });
    } catch (error) {
      debugPrint('Exercise load failed: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить упражнение. Попробуйте ещё раз.';
      });
    }
  }

  /// Запрашивает упражнение; если остались только пропущенные, идёт по кругу.
  Future<Exercise> _fetchNext() async {
    try {
      return await _api.nextExercise(
        category: widget.category,
        focus: widget.focus,
        excludeIds: List<int>.of(_skippedIds),
      );
    } on ApiException catch (error) {
      if (!error.isNotFound || _skippedIds.isEmpty) {
        rethrow;
      }
      _skippedIds.clear();
      return _api.nextExercise(category: widget.category, focus: widget.focus);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final double target = _scrollController.position.maxScrollExtent;
      if (target <= 0) {
        return;
      }
      unawaited(
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  Future<void> _submit() async {
    final Exercise? exercise = _exercise;
    final Recording? recording = _recording.recording;
    if (exercise == null || recording == null || _sending) {
      return;
    }

    unawaited(_audio.stop());
    setState(() {
      _sending = true;
      _sendError = null;
      _messageIndex = 0;
      _loadingMessage = _loadingMessages.first;
    });
    _syncClosingConfirmation();
    _startMessageCycle();

    try {
      final Assessment assessment = await _api.assess(
        audio: recording.bytes,
        exerciseId: exercise.id,
      );
      if (!mounted) {
        return;
      }
      _finishSending();
      unawaited(HapticFeedback.mediumImpact());

      final ResultAction? action = await Navigator.of(context)
          .push<ResultAction>(
            MaterialPageRoute<ResultAction>(
              builder: (BuildContext context) =>
                  ResultScreen(exercise: exercise, assessment: assessment),
            ),
          );
      if (!mounted) {
        return;
      }
      if (action == ResultAction.next) {
        await _loadNext();
      } else {
        await _recording.reset();
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _finishSending();
      if (error.requiresNewRecording) {
        _recording.reject(error.userMessage);
      } else {
        setState(() => _sendError = error.userMessage);
      }
      _scrollToBottom();
    } catch (error) {
      debugPrint('Assess failed: $error');
      if (!mounted) {
        return;
      }
      _finishSending();
      setState(
        () => _sendError = 'Не удалось проверить запись. Попробуйте ещё раз.',
      );
      _scrollToBottom();
    }
  }

  void _finishSending() {
    _messageTimer?.cancel();
    setState(() => _sending = false);
    _syncClosingConfirmation();
  }

  void _startMessageCycle() {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1600), (
      Timer timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_messageIndex >= _loadingMessages.length - 1) {
        timer.cancel();
        return;
      }
      setState(() {
        _messageIndex += 1;
        _loadingMessage = _loadingMessages[_messageIndex];
      });
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 10000) {
      final String seconds = (duration.inMilliseconds / 1000).toStringAsFixed(
        1,
      );
      return '$seconds с';
    }
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Упражнение',
      padding: EdgeInsets.zero,
      actions: <Widget>[
        IconButton(
          onPressed: _loading || _sending ? null : () => _loadNext(skip: true),
          tooltip: _exercise?.category == TrainingCategory.sentence
              ? 'Другое предложение'
              : _exercise?.category == TrainingCategory.phrase
              ? 'Другая фраза'
              : 'Другое слово',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Stack(
        children: <Widget>[
          ListenableBuilder(
            listenable: _recording,
            builder: (BuildContext context, Widget? child) =>
                _buildBody(context),
          ),
          if (_sending)
            LoadingOverlay(
              message: _loadingMessage,
              hint: 'Обычно это занимает 3–5 секунд',
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Подбираем упражнение…',
                style: TextStyle(fontSize: 16, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      if (_notFound) {
        return _NoExercises(
          onBack: () => Navigator.of(context).pop(),
          focus: widget.focus,
        );
      }
      return Padding(
        padding: AppSpacing.pagePadding,
        child: ErrorView(
          title: 'Не удалось загрузить упражнение',
          message: _error!,
          onRetry: _loadNext,
        ),
      );
    }

    final Exercise? exercise = _exercise;
    if (exercise == null) {
      return const SizedBox.shrink();
    }

    final bool compact = MediaQuery.sizeOf(context).height < 700;
    final Recording? recording = _recording.recording;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: <Widget>[
        _DifficultyBadge(difficulty: exercise.difficulty),
        if (widget.focus != null) ...<Widget>[
          const SizedBox(height: 6),
          _FocusBadge(text: 'Тренируем звук ${widget.focus!}'),
        ],
        if (exercise.reason?.label case final String label) ...<Widget>[
          const SizedBox(height: 6),
          _FocusBadge(text: label),
        ],
        SizedBox(height: compact ? 6 : 12),
        Center(
          child: WordIllustration(
            text: exercise.text,
            size: compact ? 112 : 148,
          ),
        ),
        SizedBox(height: compact ? 10 : 18),
        Center(
          child: exercise.isPhrase
              ? Text(
                  exercise.upperText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 30 : 38,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: 1,
                    color: AppColors.ink,
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    exercise.upperText,
                    style: TextStyle(
                      fontSize: compact ? 48 : 62,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: 3,
                      color: AppColors.ink,
                    ),
                  ),
                ),
        ),
        SizedBox(height: compact ? 10 : 14),
        if (exercise.isPhrase)
          const Text(
            'Проверим звуки в каждом слове',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          )
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: exercise.phonemes
                .map(
                  (String phoneme) =>
                      PhonemeChip(phoneme: phoneme, dense: true),
                )
                .toList(growable: false),
          ),
        if (_canSpeak) ...<Widget>[
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: _recording.isRecording || _sending
                  ? null
                  : () => _audio.speak(exercise.text),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Послушать образец'),
            ),
          ),
        ],
        SizedBox(height: compact ? 8 : 18),
        _buildRecorder(context, exercise),
        const SizedBox(height: 18),
        if (_sendError != null) ...<Widget>[
          _InlineError(
            title: 'Не удалось проверить запись',
            message: _sendError!,
            onRetry: _submit,
          ),
          const SizedBox(height: 14),
        ],
        PrimaryButton(
          label: 'Проверить произношение',
          icon: Icons.graphic_eq_rounded,
          onPressed: recording != null && !_sending ? _submit : null,
        ),
        const SizedBox(height: 12),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.shield_outlined, size: 16, color: AppColors.muted),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Запись уходит только на проверку и не хранится',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecorder(BuildContext context, Exercise exercise) {
    final String kind = switch (exercise.category) {
      TrainingCategory.sentence => 'предложение',
      TrainingCategory.phrase => 'фразу',
      TrainingCategory.word => 'слово',
    };
    final RecordingPhase phase = _recording.phase;
    if (phase == RecordingPhase.micDenied) {
      return _MicDenied(
        canUseDemo: _api.isMock,
        onRetry: _recording.start,
        onUseDemo: _recording.useDemoRecording,
      );
    }

    final Recording? recording = _recording.recording;

    return Column(
      children: <Widget>[
        RecordButton(
          isRecording: _recording.isRecording,
          enabled: !_recording.isBusy && !_sending,
          onPressed: _recording.toggle,
        ),
        const SizedBox(height: 4),
        if (_recording.isRecording) ...<Widget>[
          const SoundWave(active: true),
          const SizedBox(height: 4),
          Text(
            _formatDuration(_recording.elapsed),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value:
                    (_recording.elapsed.inMilliseconds /
                            (maxRecordingSeconds * 1000))
                        .clamp(0, 1),
                minHeight: 5,
                color: AppColors.danger,
                backgroundColor: AppColors.dangerSoft,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Нажмите, чтобы остановить',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ] else if (_recording.isBusy) ...<Widget>[
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(height: 8),
          Text(
            phase == RecordingPhase.starting
                ? 'Включаем микрофон…'
                : 'Сохраняем запись…',
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ] else if (recording != null) ...<Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                'Запись готова · ${_formatDuration(recording.duration)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: <Widget>[
              if (recording.url case final String url)
                TextButton.icon(
                  onPressed: _sending ? null : () => _audio.playRecording(url),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Послушать себя'),
                ),
              TextButton.icon(
                onPressed: _sending ? null : _recording.reset,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Перезаписать'),
              ),
            ],
          ),
        ] else ...<Widget>[
          Text(
            'Нажмите на микрофон и произнесите $kind',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          const Text(
            'До 20 секунд',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
        if (phase == RecordingPhase.tooShort) ...<Widget>[
          const SizedBox(height: 10),
          const _InlineNote(
            icon: Icons.timer_outlined,
            color: AppColors.warning,
            text: 'Слишком короткая запись. Нажмите и говорите чуть дольше.',
          ),
        ],
        if (_recording.error case final String message) ...<Widget>[
          const SizedBox(height: 10),
          _InlineNote(
            icon: Icons.error_outline_rounded,
            color: AppColors.danger,
            text: message,
          ),
          if (_api.isMock)
            TextButton(
              onPressed: _recording.useDemoRecording,
              child: const Text('Продолжить без записи (демо)'),
            ),
        ],
      ],
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final int difficulty;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (var index = 1; index <= 3; index++) ...<Widget>[
          Container(
            width: 18,
            height: 6,
            decoration: BoxDecoration(
              color: index <= difficulty
                  ? AppColors.primary
                  : AppColors.outline,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          if (index < 3) const SizedBox(width: 4),
        ],
        const SizedBox(width: 8),
        Text(
          'Уровень $difficulty',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _MicDenied extends StatelessWidget {
  const _MicDenied({
    required this.canUseDemo,
    required this.onRetry,
    required this.onUseDemo,
  });

  final bool canUseDemo;
  final VoidCallback onRetry;
  final VoidCallback onUseDemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.mic_off_rounded, size: 24, color: AppColors.danger),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Нет доступа к микрофону',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Разрешите доступ к микрофону в браузере или Telegram '
                      'и попробуйте снова.',
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
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('Попросить доступ снова'),
        ),
        if (canUseDemo)
          TextButton(
            onPressed: onUseDemo,
            child: const Text('Продолжить без записи (демо)'),
          ),
      ],
    );
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: AppColors.danger,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.ink,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusBadge extends StatelessWidget {
  const _FocusBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _NoExercises extends StatelessWidget {
  const _NoExercises({required this.onBack, this.focus});

  final VoidCallback onBack;
  final String? focus;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 38,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                focus == null
                    ? 'Упражнений пока нет'
                    : 'Нет упражнений со звуком $focus',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                focus == null
                    ? 'Для этой категории ещё нет заданий. '
                          'Выберите другую на главном экране.'
                    : 'Попробуйте другой звук или вернитесь на главный экран.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'На главную',
                icon: Icons.home_rounded,
                onPressed: onBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
