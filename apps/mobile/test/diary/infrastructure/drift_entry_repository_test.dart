import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/app/database.dart';
import 'package:lean_tracker/diary/application/entry_repository.dart';
import 'package:lean_tracker/diary/domain/diary_entry.dart';
import 'package:lean_tracker/diary/domain/meal.dart';
import 'package:lean_tracker/diary/domain/units.dart';
import 'package:lean_tracker/diary/infrastructure/drift_entry_repository.dart';

import '../../support/diary_samples.dart';

void main() {
  late AppDatabase db;
  late DriftEntryRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftEntryRepository(db, 'user-a');
  });

  tearDown(() => db.close());

  test('saves and reads back every field, with a null serving size and source ref', () async {
    final entry = entryOf(
      meal: Meal.dinner,
      quantity: 150.5,
      updatedAt: DateTime.utc(2026, 11, 25, 18, 30, 15),
    );

    expect(await repository.save(entry), isA<Saved>());
    final read = await repository.findById('e1');

    expect(read, isNotNull);
    expect(read?.snapshot, plainProduct);
    expect(read?.snapshot.servingSize, isNull);
    expect(read?.snapshot.sourceRef, isNull);
    expect(read?.meal, Meal.dinner);
    expect(read?.entryDate, day);
    expect(read?.quantity, 150.5);
    expect(read?.unit, EntryUnit.g);
    expect(read?.updatedAt, DateTime.utc(2026, 11, 25, 18, 30, 15));
    expect(read?.deletedAt, isNull);
  });

  test('saves and reads back a serving size and a source ref', () async {
    await repository.save(
      entryOf(snapshot: servingProduct, quantity: 2, unit: EntryUnit.serving),
    );

    final read = await repository.findById('e1');

    expect(read?.snapshot, servingProduct);
    expect(read?.unit, EntryUnit.serving);
  });

  test('saving the same id again replaces the row', () async {
    await repository.save(entryOf());
    await repository.save(entryOf(quantity: 250));

    expect((await repository.findById('e1'))?.quantity, 250);
  });

  group('watchDay', () {
    test('returns only the entries of that date', () async {
      await repository.save(entryOf(id: 'today'));
      await repository.save(entryOf(id: 'tomorrow', date: day.addDays(1)));

      final entries = await repository.watchDay(day).first;

      expect(entries.map((e) => e.id), ['today']);
    });

    test('hides soft-deleted rows (PRD §13)', () async {
      final entry = entryOf();
      await repository.save(entry);
      await repository.save(entry.delete(DateTime.utc(2026, 11, 25, 12)));

      expect(await repository.watchDay(day).first, isEmpty);
      expect(await repository.findById('e1'), isNull);
    });

    test('orders by updatedAt, then id', () async {
      await repository.save(entryOf(id: 'b', updatedAt: DateTime.utc(2026, 11, 25, 9)));
      await repository.save(entryOf(id: 'c', updatedAt: DateTime.utc(2026, 11, 25, 8)));
      await repository.save(entryOf(id: 'a', updatedAt: DateTime.utc(2026, 11, 25, 9)));

      final entries = await repository.watchDay(day).first;

      expect(entries.map((e) => e.id), ['c', 'a', 'b']);
    });

    test('emits again after a save', () async {
      final emissions = expectLater(
        repository.watchDay(day).map((entries) => entries.length),
        emitsInOrder([0, 1]),
      );
      await pumpEventQueue();

      await repository.save(entryOf());

      await emissions;
    });
  });

  group('user isolation (BR-001)', () {
    late DriftEntryRepository other;

    setUp(() => other = DriftEntryRepository(db, 'user-b'));

    test("user B's repository sees none of user A's rows", () async {
      await repository.save(entryOf());

      expect(await other.watchDay(day).first, isEmpty);
      expect(await other.findById('e1'), isNull);
    });

    test("saving an id owned by user A from user B leaves A's row unchanged", () async {
      await repository.save(entryOf(quantity: 100));

      await other.save(entryOf(quantity: 999, meal: Meal.snack));

      final mine = await repository.findById('e1');
      expect(mine?.quantity, 100);
      expect(mine?.meal, Meal.breakfast);
      expect(await other.findById('e1'), isNull);
    });
  });

  test('a row with an unknown stored value is skipped, not a crash', () async {
    await repository.save(entryOf(id: 'good'));
    await db.customStatement(
      "UPDATE diary_entries SET meal = 'brunch' WHERE id = 'good'",
    );
    await repository.save(entryOf(id: 'fine'));

    final entries = await repository.watchDay(day).first;

    expect(entries.map((e) => e.id), ['fine']);
  });

  test('a database error becomes SaveFailed', () async {
    await db.close();

    expect(await repository.save(entryOf()), isA<SaveFailed>());
  });
}
