import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app/core/api_client.dart';
import 'package:mini_app/core/auth_service.dart';
import 'package:mini_app/core/mock_backend.dart';
import 'package:mini_app/core/progress_service.dart';
import 'package:mini_app/core/telegram_bridge.dart';
import 'package:mini_app/screens/auth_gate.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('первый вход: согласие, выбор аудитории, главный экран', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'intro_seen': true,
    });
    final ApiClient api = ApiClient(
      mockBackend: MockBackend(
        authDelay: Duration.zero,
        progressDelay: Duration.zero,
      ),
    );
    final TelegramBridge telegram = TelegramBridge();
    final AuthService auth = AuthService(api: api, telegram: telegram);

    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          Provider<ApiClient>.value(value: api),
          Provider<TelegramBridge>.value(value: telegram),
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<ProgressService>.value(
            value: ProgressService(api: api),
          ),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Перед началом'), findsOneWidget);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(find.text('Продолжить'));
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(find.text('Кто будет заниматься?'), findsOneWidget);
    await tester.tap(find.text('Ребёнок'));
    await tester.pumpAndSettle();

    expect(find.text('Твой прогресс'), findsOneWidget);
    expect(auth.hasConsent, isTrue);
  });
}
