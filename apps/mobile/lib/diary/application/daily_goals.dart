/// The four daily goals as the diary needs them. The diary declares its own shape (AD3); `app/` maps
/// the settings module's goals to it.
final class DailyGoals {
  const DailyGoals({
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
      other is DailyGoals &&
      other.kcal == kcal &&
      other.protein == protein &&
      other.fat == fat &&
      other.carbs == carbs;

  @override
  int get hashCode => Object.hash(kcal, protein, fat, carbs);
}
