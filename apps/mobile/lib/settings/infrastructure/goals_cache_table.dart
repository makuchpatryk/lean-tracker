import 'package:drift/drift.dart';

/// Device cache of the user's goals, so the Diary works offline (BR-014). Named like the server table
/// but it holds only the four goals: M2's settings carry no timestamp (D-73); M6 adds it with sync.
@DataClassName('CachedGoalsRow')
class CachedGoals extends Table {
  @override
  String get tableName => 'user_settings';

  TextColumn get userId => text()();
  IntColumn get goalKcal => integer()();
  IntColumn get goalProteinG => integer()();
  IntColumn get goalFatG => integer()();
  IntColumn get goalCarbsG => integer()();

  @override
  Set<Column> get primaryKey => {userId};
}
