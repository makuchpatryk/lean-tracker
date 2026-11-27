@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/domain/meal.dart';
import 'package:lean_tracker/diary/domain/units.dart';
import 'package:lean_tracker/diary/presentation/entry_form_screen.dart';

import '../../support/diary_harness.dart';
import '../../support/diary_samples.dart';
import '../../support/fakes.dart';

Future<FakeEntryRepository> pumpCreate(
  WidgetTester tester, {
  FakeEntryRepository? repository,
  bool serving = false,
}) => pumpDiaryScreen(
  tester,
  EntryFormScreen.create(
    snapshot: serving ? servingProduct : plainProduct,
    meal: Meal.lunch,
    date: day,
  ),
  repository: repository,
);

Finder get saveButton => find.widgetWithText(FilledButton, 'Save');

/// The form scrolls, so bring the target into view before tapping it.
Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
}

String get quantityText =>
    (find.byType(TextField).evaluate().single.widget as TextField)
        .controller
        ?.text ??
    '';

void main() {
  testWidgets('an invalid quantity shows the UF-003 error and disables Save', (
    tester,
  ) async {
    await pumpCreate(tester);

    // The range rules themselves are covered in quantity_test.dart; here only the wiring.
    await tester.enterText(find.byType(TextField), '0');
    await tester.pump();

    expect(find.text('Enter a quantity from 0.1 to 10000.'), findsOneWidget);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
  });

  testWidgets('150 g of a 200 kcal product previews 300 kcal (FR-004)', (
    tester,
  ) async {
    await pumpCreate(tester);

    await tester.enterText(find.byType(TextField), '150');
    await tester.pump();

    expect(find.text('300 kcal'), findsOneWidget);
    expect(find.text('Protein 15.0 g'), findsOneWidget);
    expect(find.text('Fat 7.5 g'), findsOneWidget);
    expect(find.text('Carbs 45.0 g'), findsOneWidget);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
  });

  testWidgets('a product without a serving size has no serving chip (BR-006)', (
    tester,
  ) async {
    await pumpCreate(tester);

    expect(find.byType(ChoiceChip), findsNWidgets(1 + Meal.values.length));
    expect(find.textContaining('serving'), findsNothing);
  });

  testWidgets(
    'a product with a serving size offers a serving chip and previews it (BR-006)',
    (tester) async {
      await pumpCreate(tester, serving: true);

      await tapVisible(tester, find.text('serving (30 g)'));
      await tester.enterText(find.byType(TextField), '2');
      await tester.pump();

      expect(
        find.text('60 kcal'),
        findsOneWidget,
      ); // 2 x 30 g at 100 kcal / 100 g
    },
  );

  testWidgets('the − and + buttons step 10 g and clamp at the limits', (
    tester,
  ) async {
    await pumpCreate(tester);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(quantityText, '110');

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();
    expect(quantityText, '90');

    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();
    expect(quantityText, '0.1');
  });

  testWidgets('Save stores the entry with its snapshot and goes back', (
    tester,
  ) async {
    final repository = await pumpCreate(tester);

    await tester.enterText(find.byType(TextField), '150');
    await tester.pump();
    await tapVisible(tester, saveButton);
    await tester.pumpAndSettle();

    final saved = repository.stored.single;
    expect(saved.quantity, 150);
    expect(saved.meal, Meal.lunch);
    expect(saved.entryDate, day);
    expect(saved.snapshot, plainProduct);
    expect(find.byType(EntryFormScreen), findsNothing);
    expect(find.text('base page'), findsOneWidget);
  });

  testWidgets('a failed save shows "Could not save entry." and stays', (
    tester,
  ) async {
    final repository = FakeEntryRepository()..failSaves = true;
    await pumpCreate(tester, repository: repository);

    await tapVisible(tester, saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Could not save entry.'), findsOneWidget);
    expect(find.byType(EntryFormScreen), findsOneWidget);
  });

  group('edit', () {
    late FakeEntryRepository repository;

    setUp(() async {
      repository = FakeEntryRepository();
      await repository.save(
        entryOf(snapshot: servingProduct, quantity: 2, unit: EntryUnit.serving),
      );
    });

    Future<void> pumpEdit(WidgetTester tester) => pumpDiaryScreen(
      tester,
      const EntryFormScreen.edit(entryId: 'e1'),
      repository: repository,
    );

    testWidgets(
      'shows the stored values and saves only quantity, unit, meal and date (BR-007)',
      (tester) async {
        await pumpEdit(tester);
        expect(quantityText, '2');
        expect(find.text('Served'), findsOneWidget);

        await tapVisible(tester, find.text('Dinner'));
        await tester.enterText(find.byType(TextField), '3');
        await tester.pump();
        await tapVisible(tester, saveButton);
        await tester.pumpAndSettle();

        final saved = repository.stored.single;
        expect(saved.quantity, 3);
        expect(saved.meal, Meal.dinner);
        expect(saved.snapshot, servingProduct);
      },
    );

    testWidgets('Cancel in the delete confirmation keeps the entry', (
      tester,
    ) async {
      await pumpEdit(tester);

      await tapVisible(tester, find.text('Delete entry'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this entry?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.stored.single.deletedAt, isNull);
      expect(find.byType(EntryFormScreen), findsOneWidget);
    });

    testWidgets('Delete in the confirmation removes the entry and goes back', (
      tester,
    ) async {
      await pumpEdit(tester);

      await tapVisible(tester, find.text('Delete entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(repository.stored.single.deletedAt, isNotNull);
      expect(find.byType(EntryFormScreen), findsNothing);
    });

    testWidgets('a new entry form has no delete button', (tester) async {
      await pumpCreate(tester);

      expect(find.text('Delete entry'), findsNothing);
    });
  });
}
