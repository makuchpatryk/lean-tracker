import 'package:drift/drift.dart';

import '../application/goals_cache.dart';
import '../domain/goals.dart';
import 'goals_cache_table.drift.dart';

/// [GoalsCache] over the device database; every query filters by `user_id`.
class DriftGoalsCache implements GoalsCache {
  DriftGoalsCache(this._db) : _table = $CachedGoalsTable(_db);

  final GeneratedDatabase _db;
  final $CachedGoalsTable _table;

  @override
  Future<Goals?> read(String userId) async {
    final row = await (_db.select(
      _table,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
    if (row == null) return null;
    // The database is an untrusted boundary: values that fail the goal rules count as no cache.
    return switch (validateGoals({
      GoalField.kcal: '${row.goalKcal}',
      GoalField.protein: '${row.goalProteinG}',
      GoalField.fat: '${row.goalFatG}',
      GoalField.carbs: '${row.goalCarbsG}',
    })) {
      ValidGoals(:final goals) => goals,
      InvalidGoals() => null,
    };
  }

  @override
  Future<void> write(String userId, Goals goals) async {
    await _db
        .into(_table)
        .insertOnConflictUpdate(
          CachedGoalsCompanion.insert(
            userId: userId,
            goalKcal: goals.kcal,
            goalProteinG: goals.protein,
            goalFatG: goals.fat,
            goalCarbsG: goals.carbs,
          ),
        );
  }

  @override
  Future<void> clear(String userId) async {
    await (_db.delete(_table)..where((t) => t.userId.equals(userId))).go();
  }
}
