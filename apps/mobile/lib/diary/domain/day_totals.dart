import 'diary_entry.dart';
import 'meal.dart';
import 'nutrition.dart';

/// What a day adds up to against the kcal goal (FR-003).
final class DayTotals {
  const DayTotals({
    required this.perMeal,
    required this.total,
    required this.remainingKcal,
  });

  /// Sums [entries] per meal. All four meals are always present, an empty one with zeros. Sums use
  /// the unrounded values; `remainingKcal` is the goal minus the total and is negative over the goal.
  factory DayTotals.of(List<DiaryEntry> entries, int goalKcal) {
    final perMeal = {for (final meal in Meal.values) meal: Nutrition.zero};
    for (final entry in entries) {
      perMeal[entry.meal] =
          (perMeal[entry.meal] ?? Nutrition.zero) + entry.nutrition;
    }
    final total = perMeal.values.fold(Nutrition.zero, (sum, n) => sum + n);
    return DayTotals(
      perMeal: perMeal,
      total: total,
      remainingKcal: goalKcal - total.kcal,
    );
  }

  final Map<Meal, Nutrition> perMeal;
  final Nutrition total;
  final double remainingKcal;
}
