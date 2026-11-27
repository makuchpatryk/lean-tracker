import '../../kernel/clock.dart';
import '../../kernel/local_date.dart';
import '../../kernel/uuid.dart';
import '../domain/diary_entry.dart';
import '../domain/meal.dart';
import '../domain/product_snapshot.dart';
import '../domain/quantity.dart';
import '../domain/units.dart';
import 'entry_repository.dart';

/// Result of [AddEntry].
sealed class AddEntryResult {
  const AddEntryResult();
}

final class EntryAdded extends AddEntryResult {
  const EntryAdded(this.entry);

  final DiaryEntry entry;
}

/// The quantity text is not valid (BR-003).
final class QuantityRejected extends AddEntryResult {
  const QuantityRejected();
}

/// The unit does not fit the product (BR-006).
final class UnitRejected extends AddEntryResult {
  const UnitRejected(this.error);

  final EntryError error;
}

/// The entry could not be stored.
final class EntryNotSaved extends AddEntryResult {
  const EntryNotSaved();
}

/// Logs a product to a meal on a day (FR-004, UF-003): copies the snapshot (BR-007), gives the entry a
/// new id and stamps it with the clock.
class AddEntry {
  const AddEntry(this._repository, this._clock, this._uuid);

  final EntryRepository _repository;
  final Clock _clock;
  final Uuid _uuid;

  Future<AddEntryResult> call({
    required ProductSnapshot snapshot,
    required String quantityText,
    required EntryUnit unit,
    required Meal meal,
    required LocalDate date,
  }) async {
    final quantity = switch (parseQuantity(quantityText)) {
      ValidQuantity(:final value) => value,
      InvalidQuantity() => null,
    };
    if (quantity == null) return const QuantityRejected();

    final created = DiaryEntry.create(
      id: _uuid.v4(),
      entryDate: date,
      meal: meal,
      snapshot: snapshot,
      quantity: quantity,
      unit: unit,
      updatedAt: _clock.now().toUtc(),
    );
    return switch (created) {
      EntryRejected(:final error) => UnitRejected(error),
      EntryOk(:final entry) => switch (await _repository.save(entry)) {
        Saved() => EntryAdded(entry),
        SaveFailed() => const EntryNotSaved(),
      },
    };
  }
}
