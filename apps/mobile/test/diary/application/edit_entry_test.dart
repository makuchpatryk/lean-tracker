import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/application/edit_entry.dart';
import 'package:lean_tracker/diary/domain/meal.dart';
import 'package:lean_tracker/diary/domain/units.dart';
import 'package:lean_tracker/kernel/local_date.dart';

import '../../support/diary_samples.dart';
import '../../support/fakes.dart';

void main() {
  late FakeEntryRepository repository;
  late FakeClock clock;
  late EditEntry editEntry;

  setUp(() async {
    repository = FakeEntryRepository();
    clock = FakeClock(DateTime.utc(2026, 11, 26, 7));
    editEntry = EditEntry(repository, clock);
    await repository.save(entryOf(snapshot: servingProduct));
  });

  test('only quantity, unit, meal and date change; the snapshot stays (BR-007)', () async {
    final result = await editEntry(
      id: 'e1',
      quantityText: '2',
      unit: EntryUnit.serving,
      meal: Meal.dinner,
      date: const LocalDate(2026, 11, 26),
    );

    final entry = (result as EntryEdited).entry;
    expect(entry.quantity, 2);
    expect(entry.unit, EntryUnit.serving);
    expect(entry.meal, Meal.dinner);
    expect(entry.entryDate, const LocalDate(2026, 11, 26));
    expect(entry.snapshot, servingProduct);
    expect(entry.updatedAt, clock.current);
    expect(repository.stored.single.quantity, 2);
  });

  test('an unknown id is EditEntryNotFound', () async {
    final result = await editEntry(
      id: 'nope',
      quantityText: '2',
      unit: EntryUnit.g,
      meal: Meal.lunch,
      date: day,
    );

    expect(result, isA<EditEntryNotFound>());
  });

  test('an invalid quantity changes nothing (BR-003)', () async {
    final result = await editEntry(
      id: 'e1',
      quantityText: '0',
      unit: EntryUnit.g,
      meal: Meal.lunch,
      date: day,
    );

    expect(result, isA<EditQuantityRejected>());
    expect(repository.saves, hasLength(1)); // only the setUp save
  });

  test('a failed save is EditNotSaved', () async {
    repository.failSaves = true;

    final result = await editEntry(
      id: 'e1',
      quantityText: '5',
      unit: EntryUnit.g,
      meal: Meal.lunch,
      date: day,
    );

    expect(result, isA<EditNotSaved>());
  });
}
