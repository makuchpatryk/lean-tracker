import 'package:drift/drift.dart';

import '../../kernel/local_date.dart';
import '../application/entry_repository.dart';
import '../domain/diary_entry.dart';
import '../domain/meal.dart';
import '../domain/product_snapshot.dart';
import '../domain/units.dart';
import 'diary_entries_table.drift.dart';

/// [EntryRepository] over the device database. One instance serves one user: every query filters by
/// `user_id`, and the upsert cannot overwrite another user's row (BR-001, PRD §14). Typed queries on the
/// module's own table, so no `SELECT *` and no SQL strings (CODE_QUALITY: SQL).
class DriftEntryRepository implements EntryRepository {
  DriftEntryRepository(this._db, this._userId)
    : _table = $DiaryEntriesTable(_db);

  final GeneratedDatabase _db;
  final String _userId;
  final $DiaryEntriesTable _table;

  @override
  Stream<List<DiaryEntry>> watchDay(LocalDate date) {
    final query = _db.select(_table)
      ..where(
        (t) =>
            t.userId.equals(_userId) &
            t.entryDate.equals(date.toIso()) &
            t.deletedAt.isNull(),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.updatedAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch().map(
      (rows) => [for (final row in rows) ?_toEntry(row)],
    );
  }

  @override
  Future<DiaryEntry?> findById(String id) async {
    final query = _db.select(_table)
      ..where(
        (t) =>
            t.id.equals(id) & t.userId.equals(_userId) & t.deletedAt.isNull(),
      );
    final row = await query.getSingleOrNull();
    return row == null ? null : _toEntry(row);
  }

  @override
  Future<SaveResult> save(DiaryEntry entry) async {
    final companion = _toCompanion(entry);
    try {
      // A row with this id that belongs to another user matches the conflict but not the `where`,
      // so it is kept as it is (BR-001).
      await _db
          .into(_table)
          .insert(
            companion,
            onConflict: DoUpdate(
              (_) => companion,
              where: (old) => old.userId.equals(_userId),
            ),
          );
      return const Saved();
    } on Exception {
      // Drift and SQLite errors reach here as wrapped or remote exceptions; none crosses outward (AD5).
      return const SaveFailed();
    }
  }

  DiaryEntriesCompanion _toCompanion(DiaryEntry e) {
    final s = e.snapshot;
    return DiaryEntriesCompanion.insert(
      id: e.id,
      userId: _userId,
      entryDate: e.entryDate.toIso(),
      meal: e.meal.name,
      productName: s.name,
      source: s.source.name,
      sourceRef: Value(s.sourceRef),
      baseUnit: s.baseUnit.name,
      kcalPer100: s.kcalPer100,
      proteinPer100: s.proteinPer100,
      fatPer100: s.fatPer100,
      carbsPer100: s.carbsPer100,
      quantity: e.quantity,
      unit: e.unit.name,
      servingSize: Value(s.servingSize),
      updatedAt: e.updatedAt,
      deletedAt: Value(e.deletedAt),
    );
  }

  /// The stored row as an entry, or null when a stored value is not valid: the database is an
  /// untrusted boundary, so a damaged row is skipped instead of crashing the Diary.
  DiaryEntry? _toEntry(DiaryEntryRow row) {
    final date = LocalDate.parseIso(row.entryDate);
    final meal = Meal.values.asNameMap()[row.meal];
    final baseUnit = BaseUnit.values.asNameMap()[row.baseUnit];
    final source = EntrySource.values.asNameMap()[row.source];
    final unit = EntryUnit.values.asNameMap()[row.unit];
    if (date == null ||
        meal == null ||
        baseUnit == null ||
        source == null ||
        unit == null) {
      return null;
    }
    final created = DiaryEntry.create(
      id: row.id,
      entryDate: date,
      meal: meal,
      snapshot: ProductSnapshot(
        name: row.productName,
        baseUnit: baseUnit,
        kcalPer100: row.kcalPer100,
        proteinPer100: row.proteinPer100,
        fatPer100: row.fatPer100,
        carbsPer100: row.carbsPer100,
        servingSize: row.servingSize,
        source: source,
        sourceRef: row.sourceRef,
      ),
      quantity: row.quantity,
      unit: unit,
      updatedAt: row.updatedAt.toUtc(),
    );
    return switch (created) {
      EntryOk(:final entry) => entry,
      EntryRejected() => null,
    };
  }
}
