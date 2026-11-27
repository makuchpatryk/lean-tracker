import 'goals_repository.dart';

/// Loads the signed-in user's goals.
class LoadGoals {
  const LoadGoals(this._repository);

  final GoalsRepository _repository;

  Future<GoalsLoad> call() => _repository.load();
}
