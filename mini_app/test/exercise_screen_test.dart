import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_app/core/api_client.dart';
import 'package:mini_app/core/telegram_bridge.dart';
import 'package:mini_app/models/training_category.dart';
import 'package:mini_app/screens/exercise_screen.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fakes.dart';

const Map<int, String> _exercises = <int, String>{
  1: 'рыба',
  2: 'рак',
  3: 'лук',
};

/// Backend с детерминированной выдачей: первое не исключённое упражнение.
http.Response _nextExercise(http.Request request) {
  final Set<int> excluded =
      (request.url.queryParametersAll['exclude_id'] ?? const <String>[])
          .map(int.parse)
          .toSet();
  for (final MapEntry<int, String> entry in _exercises.entries) {
    if (!excluded.contains(entry.key)) {
      return http.Response.bytes(
        utf8.encode(
          jsonEncode(<String, Object>{
            'id': entry.key,
            'text': entry.value,
            'phonemes': <String>['А'],
            'difficulty': 1,
            'category': 'word',
          }),
        ),
        200,
      );
    }
  }
  return http.Response('{"detail":"All exercises completed"}', 404);
}

Future<FakeExerciseAudio> _pumpScreen(
  WidgetTester tester, {
  Future<http.Response> Function(http.Request request)? assess,
}) async {
  final FakeExerciseAudio audio = FakeExerciseAudio();
  final ApiClient api = ApiClient(
    baseUrl: 'http://test',
    mock: false,
    httpClient: MockClient((http.Request request) async {
      if (request.url.path.endsWith('/assess') && assess != null) {
        return assess(request);
      }
      return _nextExercise(request);
    }),
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: <SingleChildWidget>[
        Provider<ApiClient>.value(value: api),
        Provider<TelegramBridge>.value(value: TelegramBridge()),
      ],
      child: MaterialApp(
        home: ExerciseScreen(
          category: TrainingCategory.word,
          recorder: FakeRecorder(),
          audio: audio,
        ),
      ),
    ),
  );
  await _settle(tester);
  return audio;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _skip(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Другое слово'));
  await _settle(tester);
}

void main() {
  testWidgets('пропуск проходит все упражнения и идёт по кругу', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(tester);
    expect(find.text('РЫБА'), findsOneWidget);

    await _skip(tester);
    expect(find.text('РАК'), findsOneWidget);

    await _skip(tester);
    expect(find.text('ЛУК'), findsOneWidget);

    await _skip(tester);
    expect(find.text('РЫБА'), findsOneWidget);
  });

  testWidgets('образец озвучивает текст упражнения', (
    WidgetTester tester,
  ) async {
    final FakeExerciseAudio audio = await _pumpScreen(tester);

    await tester.tap(find.text('Послушать образец'));
    await _settle(tester);

    expect(audio.spoken, <String>['рыба']);
  });

  testWidgets('тишина в записи просит записать заново', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(
      tester,
      assess: (http.Request request) async => http.Response.bytes(
        utf8.encode('{"detail":"Audio is silent","code":"audio_silent"}'),
        400,
      ),
    );

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await _settle(tester);
    expect(find.text('Послушать себя'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Проверить произношение'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Проверить произношение'));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));

    expect(find.textContaining('Не слышно голоса'), findsOneWidget);
    expect(find.text('Послушать себя'), findsNothing);
  });
}
