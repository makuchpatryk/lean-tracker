import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../diary/diary.dart';
import '../settings/settings.dart';
import 'database.drift.dart';

/// The one device database. Each module owns its tables (ARCHITECTURE AD12); this composes them and
/// hands a [GeneratedDatabase] to each module's adapter.
@DriftDatabase(tables: [DiaryEntries, CachedGoals])
class AppDatabase extends $AppDatabase {
  /// For tests: pass an in-memory executor.
  AppDatabase(super.e);

  /// The app's database file in the documents directory, opened in a background isolate.
  AppDatabase.open() : super(driftDatabase(name: 'lean_tracker'));

  /// Schema v1. M4 and M5 add their tables as v2+ with `onUpgrade` steps.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}
