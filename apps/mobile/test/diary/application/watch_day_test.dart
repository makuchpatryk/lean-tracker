import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/application/daily_goals.dart';
import 'package:lean_tracker/diary/application/watch_day.dart';
import 'package:lean_tracker/diary/domain/meal.dart';

import '../../support/diary_samples.dart';
import '../../support/fakes.dart';

const goals = DailyGoals(kcal: 2000, protein: 150, fat: 70, carbs: 240);

void main() {
  late FakeEntryRepository repository;

  setUp(() => repository = FakeEntryRepository());

  test('groups entries by meal with all four meals present', () async {
    await repository.save(entryOf(id: 'a'));
    await repository.save(entryOf(id: 'b', meal: Meal.snack));

    final result = await WatchDay(repository)(day, goals).first;

    expect(result.entriesByMeal.keys, Meal.values);
    expect(result.entriesByMeal[Meal.breakfast]?.map((e) => e.id), ['a']);
    expect(result.entriesByMeal[Meal.snack]?.map((e) => e.id), ['b']);
    expect(result.entriesByMeal[Meal.lunch], isEmpty);
  });

  test('totals are computed against the goal (FR-003)', () async {
    await repository.save(entryOf(id: 'a', quantity: 150)); // 300 kcal
    await repository.save(entryOf(id: 'b', meal: Meal.lunch)); // 200 kcal

    final result = await WatchDay(repository)(day, goals).first;

    expect(result.totals.total.kcal, 500);
    expect(result.totals.remainingKcal, 1500);
  });

  test('emits again after a save', () async {
    final days = WatchDay(repository)(day, goals);

    final expectation = expectLater(
      days.map((d) => d.totals.total.kcal),
      emitsInOrder([0, 200]),
    );
    await pumpEventQueue();
    await repository.save(entryOf());

    await expectation;
  });
}
