import '../../kernel/clock.dart';
import '../../kernel/local_date.dart';
import '../domain/diary_entry.dart';
import '../domain/meal.dart';
import '../domain/quantity.dart';
import '../domain/units.dart';
import 'entry_repository.dart';

/// Result of [EditEntry].
sealed class EditEntryResult {
  const EditEntryResult();
}

final class EntryEdited extends EditEntryResult {
  const EntryEdited(this.entry);

  final DiaryEntry entry;
}

/// The quantity text is not valid (BR-003).
final class EditQuantityRejected extends EditEntryResult {
  const EditQuantityRejected();
}

/// The unit does not fit the entry's snapshot (BR-006).
final class EditUnitRejected extends EditEntryResult {
  const EditUnitRejected(this.error);

  final EntryError error;
}

/// No live entry has this id.
final class EditEntryNotFound extends EditEntryResult {
  const EditEntryNotFound();
}

final class EditNotSaved extends EditEntryResult {
  const EditNotSaved();
}

/// Changes an entry's quantity, unit, meal and date, never its snapshot (FR-004, BR-007).
class EditEntry {
  const EditEntry(this._repository, this._clock);

  final EntryRepository _repository;
  final Clock _clock;

  Future<EditEntryResult> call({
    required String id,
    required String quantityText,
    required EntryUnit unit,
    required Meal meal,
    required LocalDate date,
  }) async {
    final quantity = switch (parseQuantity(quantityText)) {
      ValidQuantity(:final value) => value,
      InvalidQuantity() => null,
    };
    if (quantity == null) return const EditQuantityRejected();

    final existing = await _repository.findById(id);
    if (existing == null) return const EditEntryNotFound();

    final revised = existing.revise(
      quantity: quantity,
      unit: unit,
      meal: meal,
      entryDate: date,
      now: _clock.now().toUtc(),
    );
    return switch (revised) {
      EntryRejected(:final error) => EditUnitRejected(error),
      EntryOk(:final entry) => switch (await _repository.save(entry)) {
        Saved() => EntryEdited(entry),
        SaveFailed() => const EditNotSaved(),
      },
    };
  }
}
