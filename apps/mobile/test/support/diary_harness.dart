import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/application/daily_goals.dart';
import 'package:lean_tracker/diary/application/product_source.dart';
import 'package:lean_tracker/diary/presentation/diary_providers.dart';
import 'package:lean_tracker/l10n/app_localizations.dart';
import 'package:lean_tracker/ui/theme.dart';

import 'fakes.dart';

const testGoals = DailyGoals(kcal: 2000, protein: 150, fat: 70, carbs: 240);

/// Pumps [screen] pushed on top of a base page (so a screen that pops itself has somewhere to go),
/// with the diary providers backed by fakes. The clock stands at 2026-11-25. The view is 360 dp wide and
/// tall enough (1400 dp) that a ListView builds every card and button.
Future<FakeEntryRepository> pumpDiaryScreen(
  WidgetTester tester,
  Widget screen, {
  FakeEntryRepository? repository,
  Locale locale = const Locale('en'),
  double textScale = 1,
  ProductSource products = const FakeProductSource(),
  DailyGoals? goals = testGoals,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 4200)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final entries = repository ?? FakeEntryRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        entryRepositoryProvider.overrideWithValue(entries),
        productSourceProvider.overrideWithValue(products),
        dailyGoalsProvider.overrideWithValue(goals),
        clockProvider.overrideWithValue(FakeClock()),
        uuidProvider.overrideWithValue(FakeUuid()),
      ],
      child: MaterialApp(
        locale: locale,
        theme: lightTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('pl')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: Text('base page')),
      ),
    ),
  );
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(MaterialPageRoute<void>(builder: (_) => screen));
  await tester.pumpAndSettle();
  return entries;
}
