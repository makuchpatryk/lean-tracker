import 'package:drift/drift.dart';

/// Device table of diary entries; the columns mirror PRD §13 `diary_entries` (names, `id`,
/// `updated_at` and `deleted_at` for sync). Numbers are REAL, the date is `yyyy-MM-dd` text and never
/// an instant (BR-004). The domain validates; there are no CHECK constraints here (the server has its own).
@DataClassName('DiaryEntryRow')
@TableIndex(name: 'diary_entries_user_date_idx', columns: {#userId, #entryDate})
class DiaryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get entryDate => text()();
  TextColumn get meal => text()();
  TextColumn get productName => text()();
  TextColumn get source => text()();
  TextColumn get sourceRef => text().nullable()();
  TextColumn get baseUnit => text()();
  RealColumn get kcalPer100 => real()();
  RealColumn get proteinPer100 => real()();
  RealColumn get fatPer100 => real()();
  RealColumn get carbsPer100 => real()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  RealColumn get servingSize => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
