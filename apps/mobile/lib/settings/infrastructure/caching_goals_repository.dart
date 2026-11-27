import '../application/goals_cache.dart';
import '../application/goals_repository.dart';
import '../domain/goals.dart';

/// Decorates the remote [GoalsRepository] with the device cache, so the Diary has goals with no
/// network (BR-014). `LoadGoals`, `SaveGoals` and their tests stay unchanged. Goal edits stay online-only
/// until sync (M6): a save that did not reach the API is not cached.
class CachingGoalsRepository implements GoalsRepository {
  const CachingGoalsRepository(this._remote, this._cache, this._userId);

  final GoalsRepository _remote;
  final GoalsCache _cache;
  final String _userId;

  @override
  Future<GoalsLoad> load() async {
    final result = await _remote.load();
    switch (result) {
      case GoalsFound(:final goals):
        await _guarded(() => _cache.write(_userId, goals));
        return result;
      case GoalsMissing():
        await _guarded(() => _cache.clear(_userId));
        return result;
      case GoalsUnavailable():
        final cached = await _cachedOrNull();
        return cached == null ? result : GoalsFound(cached);
    }
  }

  @override
  Future<GoalsSave> save(Goals goals) async {
    final result = await _remote.save(goals);
    if (result is GoalsSaved) {
      await _guarded(() => _cache.write(_userId, result.goals));
    }
    return result;
  }

  Future<Goals?> _cachedOrNull() async {
    try {
      return await _cache.read(_userId);
    } on Exception {
      return null;
    }
  }

  /// A cache failure never turns a good answer from the API into an error.
  Future<void> _guarded(Future<void> Function() action) async {
    try {
      await action();
    } on Exception {
      // The cache is best effort; the next load writes it again.
    }
  }
}
