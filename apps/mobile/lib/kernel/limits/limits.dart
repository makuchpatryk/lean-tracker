/// Rule values the app enforces. The goal ranges are mirrored from the API (apps/api/internal/kernel/limits)
/// and held equal to `openapi.yaml` by test/kernel/limits_contract_test.dart (ARCHITECTURE AD6).
abstract final class Limits {
  /// Daily energy goal in kcal (BR-003).
  static const int goalKcalMin = 500;
  static const int goalKcalMax = 10000;

  /// Daily protein, fat and carbohydrate goals in grams (BR-003).
  static const int goalMacroMin = 0;
  static const int goalMacroMax = 1000;

  /// Shortest password Supabase Auth accepts (FR-001, D-41). App-side only: it is an Auth setting, not
  /// part of the API contract.
  static const int passwordMinLength = 8;
}
