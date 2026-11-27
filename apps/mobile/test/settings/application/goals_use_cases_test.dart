import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/settings/application/goals_repository.dart';
import 'package:lean_tracker/settings/application/load_goals.dart';
import 'package:lean_tracker/settings/application/save_goals.dart';
import 'package:lean_tracker/settings/domain/goals.dart';

import '../../support/fakes.dart';

Map<GoalField, String> raw({String kcal = '2200'}) => {
  GoalField.kcal: kcal,
  GoalField.protein: '150',
  GoalField.fat: '70',
  GoalField.carbs: '240',
};

void main() {
  test(
    'invalid goals never reach the repository (FR-002 criterion 1)',
    () async {
      final repository = FakeGoalsRepository();

      final result = await SaveGoals(repository)(raw(kcal: '499'));

      expect(result, isA<GoalsInvalid>());
      expect(
        (result as GoalsInvalid).errors[GoalField.kcal],
        GoalError.outOfRange,
      );
      expect(repository.saved, isEmpty);
    },
  );

  test('valid goals are saved and returned as stored', () async {
    final repository = FakeGoalsRepository();

    final result = await SaveGoals(repository)(raw());

    const expected = Goals(kcal: 2200, protein: 150, fat: 70, carbs: 240);
    expect(result, isA<GoalsSaved>());
    expect((result as GoalsSaved).goals, expected);
    expect(repository.saved, [expected]);
  });

  test('a missing row passes through as GoalsMissing (BP-006)', () async {
    final result = await LoadGoals(FakeGoalsRepository())();

    expect(result, isA<GoalsMissing>());
  });

  test('stored goals are returned by load', () async {
    const goals = Goals(kcal: 2000, protein: 100, fat: 60, carbs: 250);
    final repository = FakeGoalsRepository(loadResult: const GoalsFound(goals));

    final result = await LoadGoals(repository)();

    expect((result as GoalsFound).goals, goals);
  });

  test('an unavailable API passes through as GoalsUnavailable', () async {
    final repository = FakeGoalsRepository(
      loadResult: const GoalsUnavailable(),
    );

    expect(await LoadGoals(repository)(), isA<GoalsUnavailable>());
  });
}
