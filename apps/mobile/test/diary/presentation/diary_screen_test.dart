import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/domain/meal.dart';
import 'package:lean_tracker/diary/domain/units.dart';
import 'package:lean_tracker/diary/presentation/diary_screen.dart';
import 'package:lean_tracker/kernel/local_date.dart';

import '../../support/diary_harness.dart';
import '../../support/diary_samples.dart';
import '../../support/fakes.dart';

const screen = DiaryScreen(onOpenMeal: _noop, onAddEntry: _noop);

void _noop(Meal meal, LocalDate date) {}

Future<FakeEntryRepository> pumpScreen(
  WidgetTester tester, {
  FakeEntryRepository? repository,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) => pumpDiaryScreen(
  tester,
  screen,
  repository: repository,
  locale: locale,
  textScale: textScale,
);

void main() {
  testWidgets(
    '300 + 200 kcal against 2000 shows consumed 500 and remaining 1500 (FR-003)',
    (tester) async {
      final repository = FakeEntryRepository();
      await repository.save(entryOf(id: 'a', quantity: 150)); // 300 kcal
      await repository.save(entryOf(id: 'b', meal: Meal.lunch)); // 200 kcal

      await pumpScreen(tester, repository: repository);

      expect(find.text('1,500'), findsOneWidget);
      expect(find.text('kcal left'), findsOneWidget);
      expect(find.text('Eaten 500 of 2,000 kcal'), findsOneWidget);
    },
  );

  testWidgets(
    'a day over the goal shows remaining with a minus sign (FR-003)',
    (tester) async {
      final repository = FakeEntryRepository();
      await repository.save(entryOf(quantity: 1500)); // 3000 kcal

      await pumpScreen(tester, repository: repository);

      expect(find.text('−1,000'), findsOneWidget);
    },
  );

  testWidgets('macros show consumed over goal', (tester) async {
    final repository = FakeEntryRepository();
    await repository.save(entryOf(quantity: 150)); // P 15, F 7.5, C 45

    await pumpScreen(tester, repository: repository);

    expect(find.text('Protein 15 / 150 g'), findsOneWidget);
    expect(find.text('Fat 8 / 70 g'), findsOneWidget);
    expect(find.text('Carbs 45 / 240 g'), findsOneWidget);
  });

  testWidgets(
    'an empty day shows zeros, four empty meals and a plus for each (UF-002)',
    (tester) async {
      await pumpScreen(tester);

      expect(find.text('2,000'), findsOneWidget);
      expect(find.text('No entries'), findsNWidgets(4));
      for (final meal in ['Breakfast', 'Lunch', 'Dinner', 'Snacks']) {
        expect(find.text(meal), findsOneWidget);
        expect(find.byTooltip('Add entry to $meal'), findsOneWidget);
      }
    },
  );

  testWidgets('a meal card shows its kcal, entry count and names', (
    tester,
  ) async {
    final repository = FakeEntryRepository();
    await repository.save(entryOf(id: 'a', quantity: 150)); // Plain, 300 kcal
    await repository.save(
      entryOf(
        id: 'b',
        snapshot: juiceProduct,
        unit: EntryUnit.ml,
        quantity: 250,
      ),
    ); // Juice, 100 kcal

    await pumpScreen(tester, repository: repository);

    expect(find.text('400 kcal · 2 entries'), findsOneWidget);
    expect(find.text('Plain, Juice'), findsOneWidget);
  });

  testWidgets('the arrows change the day and its entries (UF-002)', (
    tester,
  ) async {
    final repository = FakeEntryRepository();
    await repository.save(entryOf(id: 'next', date: day.addDays(1)));
    await pumpScreen(tester, repository: repository);
    expect(find.text('Wednesday, November 25'), findsOneWidget);
    expect(find.text('No entries'), findsNWidgets(4));

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();

    expect(find.text('Thursday, November 26'), findsOneWidget);
    expect(find.text('No entries'), findsNWidgets(3));

    await tester.tap(find.byTooltip('Previous day'));
    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();

    expect(find.text('Tuesday, November 24'), findsOneWidget);
  });

  testWidgets('the plus button and the card report the meal and the date', (
    tester,
  ) async {
    final opened = <(Meal, LocalDate)>[];
    final added = <(Meal, LocalDate)>[];
    await pumpDiaryScreen(
      tester,
      DiaryScreen(
        onOpenMeal: (meal, date) => opened.add((meal, date)),
        onAddEntry: (meal, date) => added.add((meal, date)),
      ),
    );

    await tester.tap(find.byTooltip('Add entry to Dinner'));
    await tester.tap(find.text('Lunch'));

    expect(added, [(Meal.dinner, day)]);
    expect(opened, [(Meal.lunch, day)]);
  });

  testWidgets('360 dp wide at 200 % text causes no overflow', (tester) async {
    final repository = FakeEntryRepository();
    for (final meal in Meal.values) {
      await repository.save(entryOf(id: meal.name, meal: meal, quantity: 900));
    }

    await pumpScreen(tester, repository: repository, textScale: 2);

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Polish texts, date and plurals (FR-017)', (tester) async {
    final repository = FakeEntryRepository();
    await repository.save(entryOf(id: 'a'));
    await repository.save(entryOf(id: 'b'));
    await repository.save(entryOf(id: 'c', meal: Meal.lunch));

    await pumpScreen(
      tester,
      repository: repository,
      locale: const Locale('pl'),
    );

    expect(find.text('Cześć!'), findsOneWidget);
    expect(find.text('Środa, 25 listopada'), findsOneWidget);
    expect(find.text('kcal zostało'), findsOneWidget);
    expect(find.text('Śniadanie'), findsOneWidget);
    expect(find.text('400 kcal · 2 wpisy'), findsOneWidget);
    expect(find.text('200 kcal · 1 wpis'), findsOneWidget);
    expect(find.text('Brak wpisów'), findsNWidgets(2));
  });
}
