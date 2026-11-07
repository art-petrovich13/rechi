import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_app/core/api_client.dart';
import 'package:mini_app/models/training_category.dart';
import 'package:mini_app/screens/exercise_screen.dart';
import 'package:provider/provider.dart';

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

Future<void> _pumpScreen(WidgetTester tester) async {
  final ApiClient api = ApiClient(
    baseUrl: 'http://test',
    mock: false,
    httpClient: MockClient((http.Request request) async {
      return _nextExercise(request);
    }),
  );
  await tester.pumpWidget(
    Provider<ApiClient>.value(
      value: api,
      child: const MaterialApp(
        home: ExerciseScreen(category: TrainingCategory.word),
      ),
    ),
  );
  await _settle(tester);
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
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'),
          (MethodCall call) async => null,
        );
  });

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
}
