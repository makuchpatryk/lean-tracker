import '../../kernel/limits/limits.dart';

/// The four daily goals of a user (BR-003): energy in kcal, protein, fat and carbohydrates in grams.
final class Goals {
  const Goals({
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final int kcal;
  final int protein;
  final int fat;
  final int carbs;

  @override
  bool operator ==(Object other) =>
      other is Goals &&
      other.kcal == kcal &&
      other.protein == protein &&
      other.fat == fat &&
      other.carbs == carbs;

  @override
  int get hashCode => Object.hash(kcal, protein, fat, carbs);

  @override
  String toString() =>
      'Goals(kcal: $kcal, protein: $protein, fat: $fat, carbs: $carbs)';
}

/// A goal field with its allowed range (BR-003), taken from [Limits].
enum GoalField {
  kcal(Limits.goalKcalMin, Limits.goalKcalMax),
  protein(Limits.goalMacroMin, Limits.goalMacroMax),
  fat(Limits.goalMacroMin, Limits.goalMacroMax),
  carbs(Limits.goalMacroMin, Limits.goalMacroMax);

  const GoalField(this.min, this.max);

  final int min;
  final int max;
}

/// Why a goal field is not accepted. The UI maps it to a text; the domain holds no text.
enum GoalError { missing, notInteger, outOfRange }

/// Result of [validateGoals].
sealed class GoalsInput {
  const GoalsInput();
}

/// All four fields are valid.
final class ValidGoals extends GoalsInput {
  const ValidGoals(this.goals);

  final Goals goals;
}

/// At least one field is invalid; [errors] holds only the failing fields.
final class InvalidGoals extends GoalsInput {
  const InvalidGoals(this.errors);

  final Map<GoalField, GoalError> errors;
}

/// Validates the raw text of the four goal fields (BR-003, FR-002). A missing field is an error, not
/// zero. Whole numbers only: "12.5" and "abc" are [GoalError.notInteger].
GoalsInput validateGoals(Map<GoalField, String> raw) {
  final errors = <GoalField, GoalError>{};
  final values = <GoalField, int>{};
  for (final field in GoalField.values) {
    final text = (raw[field] ?? '').trim();
    if (text.isEmpty) {
      errors[field] = GoalError.missing;
      continue;
    }
    final value = int.tryParse(text);
    if (value == null) {
      errors[field] = GoalError.notInteger;
    } else if (value < field.min || value > field.max) {
      errors[field] = GoalError.outOfRange;
    } else {
      values[field] = value;
    }
  }
  if (errors.isNotEmpty) return InvalidGoals(errors);
  return ValidGoals(
    Goals(
      kcal: values[GoalField.kcal] ?? 0,
      protein: values[GoalField.protein] ?? 0,
      fat: values[GoalField.fat] ?? 0,
      carbs: values[GoalField.carbs] ?? 0,
    ),
  );
}
