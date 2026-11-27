import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/domain/diary_entry.dart';
import 'package:lean_tracker/diary/domain/meal.dart';
import 'package:lean_tracker/diary/domain/units.dart';
import 'package:lean_tracker/kernel/local_date.dart';

import '../../support/diary_samples.dart';

EntryError? errorOf(EntryResult r) => switch (r) {
  EntryRejected(:final error) => error,
  EntryOk() => null,
};

DiaryEntry entryFrom(EntryResult r) => switch (r) {
  EntryOk(:final entry) => entry,
  EntryRejected() => throw StateError('rejected'),
};

void main() {
  test('there are four fixed meals (BR-005)', () {
    expect(Meal.values, [Meal.breakfast, Meal.lunch, Meal.dinner, Meal.snack]);
  });

  group('unit rules (BR-006)', () {
    test('serving without a serving size is rejected', () {
      final result = DiaryEntry.create(
        id: 'e1',
        entryDate: day,
        meal: Meal.lunch,
        snapshot: plainProduct,
        quantity: 1,
        unit: EntryUnit.serving,
        updatedAt: t0,
      );

      expect(errorOf(result), EntryError.servingUnavailable);
    });

    test('g for an ml product and ml for a g product are rejected', () {
      for (final (snapshot, unit) in [
        (juiceProduct, EntryUnit.g),
        (plainProduct, EntryUnit.ml),
      ]) {
        final result = DiaryEntry.create(
          id: 'e1',
          entryDate: day,
          meal: Meal.lunch,
          snapshot: snapshot,
          quantity: 100,
          unit: unit,
          updatedAt: t0,
        );

        expect(errorOf(result), EntryError.unitMismatch);
      }
    });

    test(
      'the offered units are the base unit plus serving only with a serving size',
      () {
        expect(unitsFor(plainProduct), [EntryUnit.g]);
        expect(unitsFor(servingProduct), [EntryUnit.g, EntryUnit.serving]);
        expect(unitsFor(juiceProduct), [EntryUnit.ml]);
      },
    );
  });

  group('revise (FR-004, BR-007)', () {
    test('changes quantity, unit, meal and date, and keeps the snapshot', () {
      final original = entryOf(snapshot: servingProduct, meal: Meal.breakfast);
      final now = DateTime.utc(2026, 11, 26, 9);

      final revised = entryFrom(
        original.revise(
          quantity: 2,
          unit: EntryUnit.serving,
          meal: Meal.dinner,
          entryDate: const LocalDate(2026, 11, 26),
          now: now,
        ),
      );

      expect(revised.snapshot, same(original.snapshot));
      expect(revised.id, original.id);
      expect(revised.quantity, 2);
      expect(revised.unit, EntryUnit.serving);
      expect(revised.meal, Meal.dinner);
      expect(revised.entryDate, const LocalDate(2026, 11, 26));
      expect(revised.updatedAt, now);
    });

    test('checks the unit against the snapshot again', () {
      final result = entryOf().revise(
        quantity: 1,
        unit: EntryUnit.serving,
        meal: Meal.lunch,
        entryDate: day,
        now: t0,
      );

      expect(errorOf(result), EntryError.servingUnavailable);
    });
  });

  test('delete sets deletedAt and updatedAt to now (PRD §13)', () {
    final now = DateTime.utc(2026, 11, 25, 12);

    final deleted = entryOf().delete(now);

    expect(deleted.deletedAt, now);
    expect(deleted.updatedAt, now);
    expect(deleted.id, 'e1');
  });

  test('nutrition follows the snapshot, quantity and unit', () {
    expect(entryOf(quantity: 150).nutrition.kcal, 300);
  });
}
