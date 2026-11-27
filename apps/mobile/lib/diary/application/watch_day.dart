import '../../kernel/local_date.dart';
import '../domain/day_totals.dart';
import '../domain/diary_entry.dart';
import '../domain/meal.dart';
import 'daily_goals.dart';
import 'entry_repository.dart';

/// One day of the Diary: its entries grouped by meal, with totals against the goals (FR-003).
final class DiaryDay {
  const DiaryDay({
    required this.date,
    required this.goals,
    required this.entriesByMeal,
    required this.totals,
  });

  final LocalDate date;
  final DailyGoals goals;

  /// All four meals are present, an empty one with an empty list.
  final Map<Meal, List<DiaryEntry>> entriesByMeal;
  final DayTotals totals;
}

/// Follows the entries of a day and sums them against the goals (FR-003).
class WatchDay {
  const WatchDay(this._repository);

  final EntryRepository _repository;

  Stream<DiaryDay> call(LocalDate date, DailyGoals goals) {
    return _repository.watchDay(date).map((entries) {
      final byMeal = {for (final meal in Meal.values) meal: <DiaryEntry>[]};
      for (final entry in entries) {
        byMeal[entry.meal]?.add(entry);
      }
      return DiaryDay(
        date: date,
        goals: goals,
        entriesByMeal: byMeal,
        totals: DayTotals.of(entries, goals.kcal),
      );
    });
  }
}
