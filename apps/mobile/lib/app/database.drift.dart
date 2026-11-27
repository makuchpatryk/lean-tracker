// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:lean_tracker/diary/infrastructure/diary_entries_table.drift.dart'
    as i1;
import 'package:lean_tracker/settings/infrastructure/goals_cache_table.drift.dart'
    as i2;

abstract class $AppDatabase extends i0.GeneratedDatabase {
  $AppDatabase(i0.QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final i1.$DiaryEntriesTable diaryEntries = i1.$DiaryEntriesTable(this);
  late final i2.$CachedGoalsTable cachedGoals = i2.$CachedGoalsTable(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    diaryEntries,
    cachedGoals,
    i1.diaryEntriesUserDateIdx,
  ];
}

class $AppDatabaseManager {
  final $AppDatabase _db;
  $AppDatabaseManager(this._db);
  i1.$$DiaryEntriesTableTableManager get diaryEntries =>
      i1.$$DiaryEntriesTableTableManager(_db, _db.diaryEntries);
  i2.$$CachedGoalsTableTableManager get cachedGoals =>
      i2.$$CachedGoalsTableTableManager(_db, _db.cachedGoals);
}
