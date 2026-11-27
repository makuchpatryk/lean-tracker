import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/settings/domain/goals.dart';

Map<GoalField, String> raw({
  String kcal = '2000',
  String protein = '100',
  String fat = '60',
  String carbs = '250',
}) => {
  GoalField.kcal: kcal,
  GoalField.protein: protein,
  GoalField.fat: fat,
  GoalField.carbs: carbs,
};

GoalError? errorOf(GoalsInput input, GoalField field) =>
    input is InvalidGoals ? input.errors[field] : null;

void main() {
  group('kcal range (BR-003)', () {
    test('499 is out of range', () {
      expect(
        errorOf(validateGoals(raw(kcal: '499')), GoalField.kcal),
        GoalError.outOfRange,
      );
    });
    test('500 and 10000 are valid', () {
      expect(validateGoals(raw(kcal: '500')), isA<ValidGoals>());
      expect(validateGoals(raw(kcal: '10000')), isA<ValidGoals>());
    });
    test('10001 is out of range', () {
      expect(
        errorOf(validateGoals(raw(kcal: '10001')), GoalField.kcal),
        GoalError.outOfRange,
      );
    });
  });

  group('macro range (BR-003)', () {
    final fields = {
      GoalField.protein: (String v) => raw(protein: v),
      GoalField.fat: (String v) => raw(fat: v),
      GoalField.carbs: (String v) => raw(carbs: v),
    };
    for (final entry in fields.entries) {
      test('${entry.key.name}: -1 and 1001 are out of range', () {
        for (final value in ['-1', '1001']) {
          expect(
            errorOf(validateGoals(entry.value(value)), entry.key),
            GoalError.outOfRange,
            reason: value,
          );
        }
      });
      test('${entry.key.name}: 0 and 1000 are valid', () {
        expect(validateGoals(entry.value('0')), isA<ValidGoals>());
        expect(validateGoals(entry.value('1000')), isA<ValidGoals>());
      });
    }
  });

  group('malformed input', () {
    test('empty and blank fields are missing', () {
      final input = validateGoals(raw(kcal: '', protein: '   '));
      expect(errorOf(input, GoalField.kcal), GoalError.missing);
      expect(errorOf(input, GoalField.protein), GoalError.missing);
    });
    test('a field absent from the map is missing', () {
      expect(
        errorOf(validateGoals({GoalField.kcal: '2000'}), GoalField.fat),
        GoalError.missing,
      );
    });
    test('12.5 and abc are not integers', () {
      expect(
        errorOf(validateGoals(raw(kcal: '12.5')), GoalField.kcal),
        GoalError.notInteger,
      );
      expect(
        errorOf(validateGoals(raw(fat: 'abc')), GoalField.fat),
        GoalError.notInteger,
      );
    });
    test('only the failing fields are reported', () {
      final input = validateGoals(raw(kcal: '499', carbs: 'x'));
      expect(input, isA<InvalidGoals>());
      expect((input as InvalidGoals).errors.keys, {
        GoalField.kcal,
        GoalField.carbs,
      });
    });
  });

  test('all valid returns the parsed goals, trimmed', () {
    final input = validateGoals(raw(kcal: ' 2200 ', protein: '150'));
    expect(input, isA<ValidGoals>());
    expect(
      (input as ValidGoals).goals,
      const Goals(kcal: 2200, protein: 150, fat: 60, carbs: 250),
    );
  });
}
