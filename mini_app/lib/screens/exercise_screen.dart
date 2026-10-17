import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mini_app/core/api_client.dart';
import 'package:mini_app/core/api_exception.dart';
import 'package:mini_app/core/audio_recorder.dart';
import 'package:mini_app/core/constants.dart';
import 'package:mini_app/models/assessment.dart';
import 'package:mini_app/models/exercise.dart';
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

/// Экран упражнения: слово, запись WAV и отправка на проверку.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

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
  final AudioRecorderService _recorder = AudioRecorderService();
  final ScrollController _scrollController = ScrollController();

  Exercise? _exercise;
  bool _loading = true;
  String? _error;
  bool _notFound = false;

  bool _starting = false;
  bool _recording = false;
  Uint8List? _audio;
  Duration _duration = Duration.zero;
  bool _micDenied = false;
  bool _tooShort = false;
  String? _recordError;
  Timer? _timer;

  bool _sending = false;
  String? _sendError;
  String _loadingMessage = _loadingMessages.first;
  Timer? _messageTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiClient>();
    _loadNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageTimer?.cancel();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadNext() async {
    _timer?.cancel();
    _messageTimer?.cancel();
    if (_recording) {
      unawaited(_recorder.cancel());
    }

    setState(() {
      _loading = true;
      _error = null;
      _notFound = false;
      _exercise = null;
      _starting = false;
      _recording = false;
      _audio = null;
      _duration = Duration.zero;
      _micDenied = false;
      _tooShort = false;
      _recordError = null;
      _sendError = null;
    });

    try {
      final Exercise exercise = await _api.nextExercise();
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

  Future<void> _startRecording() async {
    if (_recording || _starting || _sending) {
      return;
    }

    setState(() {
      _starting = true;
      _micDenied = false;
      _tooShort = false;
      _recordError = null;
      _sendError = null;
    });

    try {
      final bool allowed = await _recorder.ensurePermission();
      if (!mounted) {
        return;
      }
      if (!allowed) {
        setState(() {
          _starting = false;
          _micDenied = true;
        });
        return;
      }

      await _recorder.start();
      if (!mounted) {
        return;
      }

      setState(() {
        _starting = false;
        _recording = true;
        _audio = null;
        _duration = Duration.zero;
      });
      _startTimer();
      unawaited(HapticFeedback.lightImpact());
    } on RecordingException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _starting = false;
        _recording = false;
        _recordError = error.message;
      });
    } catch (error) {
      debugPrint('Recording start failed: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _starting = false;
        _recording = false;
        _recordError = 'Не удалось начать запись. Попробуйте ещё раз.';
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _duration = _recorder.elapsed);
      if (_duration.inMilliseconds >= maxRecordingSeconds * 1000) {
        unawaited(_stopRecording(autoStopped: true));
      }
    });
  }

  Future<void> _stopRecording({bool autoStopped = false}) async {
    if (!_recording) {
      return;
    }

    _timer?.cancel();
    final Duration duration = _recorder.elapsed;
    setState(() {
      _recording = false;
      _duration = duration;
    });

    try {
      final Uint8List? bytes = await _recorder.stop();
      if (!mounted) {
        return;
      }

      if (bytes == null ||
          bytes.length < 44 ||
          duration < minRecordingDuration) {
        setState(() {
          _audio = null;
          _tooShort = true;
        });
        return;
      }

      setState(() {
        _audio = bytes;
        _tooShort = false;
        _recordError = null;
      });
      _scrollToBottom();
      unawaited(HapticFeedback.mediumImpact());
      if (autoStopped) {
        _showSnack('Запись остановлена на 10 секундах.');
      }
    } on RecordingException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _audio = null;
        _recordError = error.message;
      });
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

  void _resetRecording() {
    _timer?.cancel();
    if (_recording) {
      unawaited(_recorder.cancel());
    }
    setState(() {
      _starting = false;
      _recording = false;
      _audio = null;
      _duration = Duration.zero;
      _micDenied = false;
      _tooShort = false;
      _recordError = null;
      _sendError = null;
    });
  }

  void _useDemoAudio() {
    setState(() {
      _audio = Uint8List.fromList(List<int>.filled(32000, 0));
      _duration = const Duration(seconds: 1);
      _micDenied = false;
      _tooShort = false;
      _recordError = null;
    });
    _scrollToBottom();
  }

  Future<void> _submit() async {
    final Exercise? exercise = _exercise;
    final Uint8List? audio = _audio;
    if (exercise == null || audio == null || _sending) {
      return;
    }

    setState(() {
      _sending = true;
      _sendError = null;
      _messageIndex = 0;
      _loadingMessage = _loadingMessages.first;
    });
    _startMessageCycle();

    try {
      final Assessment assessment = await _api.assess(
        audio: audio,
        exerciseId: exercise.id,
      );
      if (!mounted) {
        return;
      }
      _messageTimer?.cancel();
      setState(() => _sending = false);
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
        _resetRecording();
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _messageTimer?.cancel();
      setState(() {
        _sending = false;
        _sendError = error.userMessage;
      });
      _scrollToBottom();
    } catch (error) {
      debugPrint('Assess failed: $error');
      if (!mounted) {
        return;
      }
      _messageTimer?.cancel();
      setState(() {
        _sending = false;
        _sendError = 'Не удалось проверить запись. Попробуйте ещё раз.';
      });
      _scrollToBottom();
    }
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
          onPressed: _loading || _sending ? null : _loadNext,
          tooltip: 'Другое слово',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Stack(
        children: <Widget>[
          _buildBody(context),
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
                'Подбираем слово…',
                style: TextStyle(fontSize: 16, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      if (_notFound) {
        return _NoExercises(onBack: () => Navigator.of(context).pop());
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

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: <Widget>[
        _DifficultyBadge(difficulty: exercise.difficulty),
        SizedBox(height: compact ? 6 : 12),
        Center(
          child: WordIllustration(
            text: exercise.text,
            size: compact ? 112 : 148,
          ),
        ),
        SizedBox(height: compact ? 10 : 18),
        Center(
          child: FittedBox(
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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: exercise.phonemes
              .map(
                (String phoneme) => PhonemeChip(phoneme: phoneme, dense: true),
              )
              .toList(growable: false),
        ),
        SizedBox(height: compact ? 8 : 22),
        _buildRecorder(context),
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
          onPressed: _audio != null && !_recording && !_starting
              ? _submit
              : null,
        ),
        const SizedBox(height: 12),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.shield_outlined, size: 16, color: AppColors.muted),
              SizedBox(width: 6),
              Text(
                'Аудио не сохраняется',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecorder(BuildContext context) {
    if (_micDenied) {
      return _MicDenied(
        canUseDemo: _api.isMock,
        onRetry: _startRecording,
        onUseDemo: _useDemoAudio,
      );
    }

    final bool hasAudio = _audio != null;

    return Column(
      children: <Widget>[
        RecordButton(
          isRecording: _recording,
          enabled: !_starting && !_sending,
          onPressed: _recording ? _stopRecording : _startRecording,
        ),
        const SizedBox(height: 4),
        if (_recording) ...<Widget>[
          const SoundWave(active: true),
          const SizedBox(height: 4),
          Text(
            _formatDuration(_duration),
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
                value: (_duration.inMilliseconds / (maxRecordingSeconds * 1000))
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
        ] else if (_starting) ...<Widget>[
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(height: 8),
          const Text(
            'Включаем микрофон…',
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ] else if (hasAudio) ...<Widget>[
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
                'Запись готова · ${_formatDuration(_duration)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: _resetRecording,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Перезаписать'),
          ),
        ] else ...<Widget>[
          const Text(
            'Нажмите на микрофон и произнесите слово',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          const Text(
            'До 10 секунд',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
        if (_tooShort) ...<Widget>[
          const SizedBox(height: 10),
          const _InlineNote(
            icon: Icons.timer_outlined,
            color: AppColors.warning,
            text: 'Слишком короткая запись. Нажмите и говорите чуть дольше.',
          ),
        ],
        if (_recordError != null) ...<Widget>[
          const SizedBox(height: 10),
          _InlineNote(
            icon: Icons.error_outline_rounded,
            color: AppColors.danger,
            text: _recordError!,
          ),
          if (_api.isMock)
            TextButton(
              onPressed: _useDemoAudio,
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

class _NoExercises extends StatelessWidget {
  const _NoExercises({required this.onBack});

  final VoidCallback onBack;

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
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  size: 38,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'На сегодня всё!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Все упражнения пройдены. Возвращайтесь завтра — '
                'или начните заново с главного экрана.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
