import '../domain/goals.dart';

/// A device copy of the user's goals, so the Diary works with no network (BR-014). Declared here,
/// implemented in `infrastructure`. Every method takes the user id, so one user's cache is never read
/// as another's (BR-001).
abstract interface class GoalsCache {
  /// The cached goals of [userId], or null when there are none or they are not valid.
  Future<Goals?> read(String userId);

  Future<void> write(String userId, Goals goals);

  Future<void> clear(String userId);
}
