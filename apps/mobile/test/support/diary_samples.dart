import 'package:lean_tracker/diary/domain/diary_entry.dart';
import 'package:lean_tracker/diary/domain/meal.dart';
import 'package:lean_tracker/diary/domain/product_snapshot.dart';
import 'package:lean_tracker/diary/domain/units.dart';
import 'package:lean_tracker/kernel/local_date.dart';

/// 200 kcal per 100 g, no serving (the FR-004 example).
const plainProduct = ProductSnapshot(
  name: 'Plain',
  baseUnit: BaseUnit.g,
  kcalPer100: 200,
  proteinPer100: 10,
  fatPer100: 5,
  carbsPer100: 30,
  source: EntrySource.manual,
);

/// 100 kcal per 100 g with a 30 g serving (the FR-004 serving example).
const servingProduct = ProductSnapshot(
  name: 'Served',
  baseUnit: BaseUnit.g,
  kcalPer100: 100,
  proteinPer100: 20,
  fatPer100: 10,
  carbsPer100: 50,
  servingSize: 30,
  source: EntrySource.own,
  sourceRef: 'ref-1',
);

const juiceProduct = ProductSnapshot(
  name: 'Juice',
  baseUnit: BaseUnit.ml,
  kcalPer100: 40,
  proteinPer100: 0.5,
  fatPer100: 0,
  carbsPer100: 9,
  source: EntrySource.manual,
);

const day = LocalDate(2026, 11, 25);
final t0 = DateTime.utc(2026, 11, 25, 8);

/// A valid entry; throws if the arguments are not a legal combination.
DiaryEntry entryOf({
  String id = 'e1',
  LocalDate date = day,
  Meal meal = Meal.breakfast,
  ProductSnapshot snapshot = plainProduct,
  double quantity = 100,
  EntryUnit unit = EntryUnit.g,
  DateTime? updatedAt,
}) {
  final result = DiaryEntry.create(
    id: id,
    entryDate: date,
    meal: meal,
    snapshot: snapshot,
    quantity: quantity,
    unit: unit,
    updatedAt: updatedAt ?? t0,
  );
  return switch (result) {
    EntryOk(:final entry) => entry,
    EntryRejected(:final error) => throw StateError('sample rejected: $error'),
  };
}
