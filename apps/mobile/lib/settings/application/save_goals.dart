import '../domain/goals.dart';
import 'goals_repository.dart';

/// Validates the raw form values and stores the goals (FR-002, BR-003).
class SaveGoals {
  const SaveGoals(this._repository);

  final GoalsRepository _repository;

  /// Invalid input returns [GoalsInvalid] and nothing is sent.
  Future<GoalsSave> call(Map<GoalField, String> raw) async {
    return switch (validateGoals(raw)) {
      InvalidGoals(:final errors) => GoalsInvalid(errors),
      ValidGoals(:final goals) => _repository.save(goals),
    };
  }
}
