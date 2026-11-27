import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/domain/day_totals.dart';
import 'package:lean_tracker/diary/domain/meal.dart';

import '../../support/diary_samples.dart';

void main() {
  test(
    '300 + 200 kcal against a 2000 goal: consumed 500, remaining 1500 (FR-003)',
    () {
      final totals = DayTotals.of([
        entryOf(id: 'a', quantity: 150), // 300 kcal
        entryOf(id: 'b', meal: Meal.lunch, quantity: 100), // 200 kcal
      ], 2000);

      expect(totals.total.kcal, 500);
      expect(totals.remainingKcal, 1500);
      expect(totals.perMeal[Meal.breakfast]?.kcal, 300);
      expect(totals.perMeal[Meal.lunch]?.kcal, 200);
    },
  );

  test('a day over the goal has a negative remaining value (FR-003)', () {
    final totals = DayTotals.of([entryOf(quantity: 1500)], 2000); // 3000 kcal

    expect(totals.remainingKcal, -1000);
  });

  test('an empty day has zeros and all four meals (FR-003 edge case)', () {
    final totals = DayTotals.of([], 2000);

    expect(totals.total.kcal, 0);
    expect(totals.remainingKcal, 2000);
    expect(totals.perMeal.keys, Meal.values);
    expect(totals.perMeal.values.every((n) => n.kcal == 0), isTrue);
  });

  test('macros are summed too', () {
    final totals = DayTotals.of([
      entryOf(id: 'a'),
      entryOf(id: 'b', meal: Meal.snack),
    ], 2000);

    expect(totals.total.protein, 20);
    expect(totals.total.carbs, 60);
  });
}
