import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/widgets/phoneme_chip.dart';
import 'package:mini_app/widgets/score_badge.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('PhonemeChip показывает звук и балл', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const PhonemeChip(phoneme: 'Р', score: 45, isProblematic: true)),
    );

    expect(find.text('Р'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
  });

  testWidgets('ScoreBadge показывает оценку из 100', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const ScoreBadge(score: 78)));
    await tester.pumpAndSettle();

    expect(find.text('78'), findsOneWidget);
    expect(find.text('из 100'), findsOneWidget);
  });

  testWidgets('PhonemeChip без балла показывает только букву', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const PhonemeChip(phoneme: 'Ш')));

    expect(find.text('Ш'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
