import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/application/add_entry.dart';
import 'package:lean_tracker/diary/domain/diary_entry.dart';
import 'package:lean_tracker/diary/domain/meal.dart';
import 'package:lean_tracker/diary/domain/units.dart';

import '../../support/diary_samples.dart';
import '../../support/fakes.dart';

void main() {
  late FakeEntryRepository repository;
  late FakeClock clock;
  late AddEntry addEntry;

  setUp(() {
    repository = FakeEntryRepository();
    clock = FakeClock(DateTime(2026, 11, 25, 9));
    addEntry = AddEntry(repository, clock, FakeUuid());
  });

  Future<AddEntryResult> add({
    String quantity = '150',
    EntryUnit unit = EntryUnit.g,
  }) => addEntry(
    snapshot: plainProduct,
    quantityText: quantity,
    unit: unit,
    meal: Meal.lunch,
    date: day,
  );

  test(
    '150 g of a 200 kcal product saves an entry of 300 kcal (FR-004)',
    () async {
      final result = await add();

      final entry = (result as EntryAdded).entry;
      expect(entry.nutrition.kcal, 300);
      expect(repository.stored, hasLength(1));
    },
  );

  test('the id comes from Uuid and updatedAt from Clock in UTC', () async {
    final entry = ((await add()) as EntryAdded).entry;

    expect(entry.id, 'id-1');
    expect(entry.updatedAt, clock.current.toUtc());
    expect(entry.updatedAt.isUtc, isTrue);
    expect(entry.entryDate, day);
    expect(entry.meal, Meal.lunch);
  });

  test('the snapshot is copied from the product (BR-007)', () async {
    final entry = ((await add()) as EntryAdded).entry;

    expect(entry.snapshot, plainProduct);
  });

  test('an invalid quantity saves nothing (BR-003)', () async {
    for (final text in ['', '0', '10000.1', '1.25', 'abc']) {
      expect(await add(quantity: text), isA<QuantityRejected>(), reason: text);
    }

    expect(repository.saves, isEmpty);
  });

  test('a unit that does not fit the product saves nothing (BR-006)', () async {
    final result = await add(unit: EntryUnit.serving);

    expect((result as UnitRejected).error, EntryError.servingUnavailable);
    expect(repository.saves, isEmpty);
  });

  test('SaveFailed becomes EntryNotSaved', () async {
    repository.failSaves = true;

    expect(await add(), isA<EntryNotSaved>());
  });
}
