import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/application/delete_entry.dart';

import '../../support/diary_samples.dart';
import '../../support/fakes.dart';

void main() {
  late FakeEntryRepository repository;
  late FakeClock clock;
  late DeleteEntry deleteEntry;

  setUp(() async {
    repository = FakeEntryRepository();
    clock = FakeClock(DateTime.utc(2026, 11, 26, 7));
    deleteEntry = DeleteEntry(repository, clock);
    await repository.save(entryOf());
  });

  test(
    'a delete is soft: the row stays with deletedAt and updatedAt set',
    () async {
      expect(await deleteEntry('e1'), isA<EntryDeleted>());

      final row = repository.stored.single;
      expect(row.deletedAt, clock.current);
      expect(row.updatedAt, clock.current);
    },
  );

  test('the deleted entry is gone from watchDay', () async {
    await deleteEntry('e1');

    expect(await repository.watchDay(day).first, isEmpty);
  });

  test('an unknown or already deleted id is DeleteEntryNotFound', () async {
    expect(await deleteEntry('nope'), isA<DeleteEntryNotFound>());
    await deleteEntry('e1');
    expect(await deleteEntry('e1'), isA<DeleteEntryNotFound>());
  });

  test('a failed save is DeleteNotSaved', () async {
    repository.failSaves = true;

    expect(await deleteEntry('e1'), isA<DeleteNotSaved>());
  });
}
