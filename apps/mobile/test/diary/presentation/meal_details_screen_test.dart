import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/domain/meal.dart';
import 'package:lean_tracker/diary/presentation/meal_details_screen.dart';

import '../../support/diary_harness.dart';
import '../../support/diary_samples.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('shows the meal total and each entry with its line (UF-002)', (
    tester,
  ) async {
    final repository = FakeEntryRepository();
    await repository.save(entryOf(id: 'a', quantity: 150)); // 300 kcal
    await repository.save(entryOf(id: 'b', meal: Meal.lunch)); // another meal

    await pumpDiaryScreen(
      tester,
      MealDetailsScreen(
        meal: Meal.breakfast,
        date: day,
        onAddProduct: () {},
        onOpenEntry: (_) {},
      ),
      repository: repository,
    );

    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('kcal in this meal'), findsOneWidget);
    expect(find.text('Plain'), findsOneWidget);
    expect(find.text('150 g · P 15 · F 8 · C 45'), findsOneWidget);
    expect(find.text('300 kcal'), findsOneWidget);
    expect(find.text('No entries'), findsNothing);
  });

  testWidgets('an empty meal shows "No entries"', (tester) async {
    await pumpDiaryScreen(
      tester,
      MealDetailsScreen(
        meal: Meal.snack,
        date: day,
        onAddProduct: () {},
        onOpenEntry: (_) {},
      ),
    );

    expect(find.text('No entries'), findsOneWidget);
  });

  testWidgets('tapping an entry opens it; "Add product" opens Add entry', (
    tester,
  ) async {
    final repository = FakeEntryRepository();
    await repository.save(entryOf(id: 'a'));
    final opened = <String>[];
    var added = 0;

    await pumpDiaryScreen(
      tester,
      MealDetailsScreen(
        meal: Meal.breakfast,
        date: day,
        onAddProduct: () => added++,
        onOpenEntry: opened.add,
      ),
      repository: repository,
    );

    await tester.tap(find.text('Plain'));
    await tester.tap(find.text('Add product'));

    expect(opened, ['a']);
    expect(added, 1);
  });
}
