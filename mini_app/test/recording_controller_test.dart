import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app/core/recording_controller.dart';

import 'fakes.dart';

void main() {
  late FakeRecorder recorder;
  late RecordingController controller;

  setUp(() {
    recorder = FakeRecorder();
    controller = RecordingController(
      recorder: recorder,
      tick: const Duration(milliseconds: 10),
    );
  });

  tearDown(() => controller.dispose());

  test('запись проходит все этапы и сохраняет длительность', () async {
    await controller.start();
    expect(controller.phase, RecordingPhase.recording);

    await controller.stop();

    expect(controller.phase, RecordingPhase.recorded);
    expect(controller.recording?.duration, const Duration(seconds: 2));
    expect(controller.recording?.url, 'blob:fake');
  });

  test('без доступа к микрофону — micDenied', () async {
    recorder.allowed = false;

    await controller.start();

    expect(controller.phase, RecordingPhase.micDenied);
  });

  test('слишком короткая запись не сохраняется', () async {
    recorder.fakeElapsed = const Duration(milliseconds: 300);
    await controller.start();

    await controller.stop();

    expect(controller.phase, RecordingPhase.tooShort);
    expect(controller.hasRecording, isFalse);
  });

  test('повторное нажатие во время остановки не начинает запись', () async {
    await controller.start();
    final Future<void> stopping = controller.stop();

    await controller.start();
    await stopping;

    expect(recorder.starts, 1);
    expect(controller.phase, RecordingPhase.recorded);
  });

  test('останавливается сама на лимите', () async {
    recorder.fakeElapsed = const Duration(seconds: 20);
    await controller.start();

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.phase, RecordingPhase.recorded);
    expect(controller.autoStopped, isTrue);
  });

  test('отказ сервера убирает запись и показывает причину', () async {
    await controller.start();
    await controller.stop();

    controller.reject('Не слышно голоса.');

    expect(controller.phase, RecordingPhase.failed);
    expect(controller.error, 'Не слышно голоса.');
    expect(controller.hasRecording, isFalse);
  });
}
