import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/l10n/app_localizations.dart';
import 'package:lean_tracker/settings/presentation/goals_form.dart';
import 'package:lean_tracker/settings/settings.dart';
import 'package:lean_tracker/ui/theme.dart';

import '../../support/fakes.dart';

Future<FakeGoalsRepository> pumpForm(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repository = FakeGoalsRepository();
  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('pl')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: GoalsForm(
            submitLabel: 'Save and go to diary',
            onSave: SaveGoals(repository).call,
          ),
        ),
      ),
    ),
  );
  return repository;
}

Future<void> fill(
  WidgetTester tester, {
  String kcal = '2200',
  String protein = '150',
  String fat = '70',
  String carbs = '240',
}) async {
  final values = [kcal, protein, fat, carbs];
  for (var i = 0; i < values.length; i++) {
    await tester.enterText(find.byType(TextField).at(i), values[i]);
  }
  await tester.pump();
}

bool saveEnabled(WidgetTester tester) =>
    tester
        .widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save and go to diary'),
        )
        .onPressed !=
    null;

void main() {
  testWidgets('Save is disabled while the fields are empty', (tester) async {
    await pumpForm(tester);

    expect(saveEnabled(tester), isFalse);
  });

  testWidgets(
    'kcal 499 shows the range error and disables Save (FR-002 criterion 1)',
    (tester) async {
      final repository = await pumpForm(tester);

      await fill(tester, kcal: '499');

      expect(find.text('Enter a value from 500 to 10000.'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
      expect(repository.saved, isEmpty);
    },
  );

  testWidgets('a macro above 1000 shows the macro range error', (tester) async {
    await pumpForm(tester);

    await fill(tester, protein: '1001');

    expect(find.text('Enter a value from 0 to 1000.'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('four valid values enable Save and store the goals', (
    tester,
  ) async {
    final repository = await pumpForm(tester);

    await fill(tester);
    expect(saveEnabled(tester), isTrue);
    await tester.tap(find.widgetWithText(FilledButton, 'Save and go to diary'));
    await tester.pumpAndSettle();

    expect(repository.saved, [
      const Goals(kcal: 2200, protein: 150, fat: 70, carbs: 240),
    ]);
  });
}
