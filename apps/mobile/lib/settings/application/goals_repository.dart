import '../domain/goals.dart';

/// Where the goals live. Declared by the use cases, implemented in `infrastructure` (ports and adapters).
abstract interface class GoalsRepository {
  Future<GoalsLoad> load();
  Future<GoalsSave> save(Goals goals);
}

/// Result of loading the goals. Failures are values, never exceptions (CODE_QUALITY: errors).
sealed class GoalsLoad {
  const GoalsLoad();
}

final class GoalsFound extends GoalsLoad {
  const GoalsFound(this.goals);

  final Goals goals;
}

/// The user has saved no goals yet: show the goals gate (BP-006).
final class GoalsMissing extends GoalsLoad {
  const GoalsMissing();
}

/// The goals could not be read: no connection, timeout or a server error.
final class GoalsUnavailable extends GoalsLoad {
  const GoalsUnavailable();
}

/// Result of saving the goals.
sealed class GoalsSave {
  const GoalsSave();
}

final class GoalsSaved extends GoalsSave {
  const GoalsSaved(this.goals);

  final Goals goals;
}

/// The API refused the values. The form validates first, so this means the app and the API disagree.
final class GoalsRejected extends GoalsSave {
  const GoalsRejected();
}

/// The goals could not be sent: no connection or timeout.
final class GoalsOffline extends GoalsSave {
  const GoalsOffline();
}

/// A field failed validation. Only the `SaveGoals` use case returns it, before it calls the repository.
final class GoalsInvalid extends GoalsSave {
  const GoalsInvalid(this.errors);

  final Map<GoalField, GoalError> errors;
}
