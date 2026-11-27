import '../../kernel/local_date.dart';
import 'meal.dart';
import 'nutrition.dart';
import 'product_snapshot.dart';
import 'units.dart';

/// Why an entry is not accepted (BR-006). The UI maps it to a text; the domain holds no text.
enum EntryError {
  /// `serving` was chosen but the snapshot has no serving size.
  servingUnavailable,

  /// `g` for a product counted in ml, or `ml` for one counted in g: there is no conversion.
  unitMismatch,
}

/// Result of creating or revising an entry.
sealed class EntryResult {
  const EntryResult();
}

final class EntryOk extends EntryResult {
  const EntryOk(this.entry);

  final DiaryEntry entry;
}

final class EntryRejected extends EntryResult {
  const EntryRejected(this.error);

  final EntryError error;
}

/// One food logged on a day: a snapshot of the product, a quantity in a unit, a meal and a date
/// (FR-004). The snapshot never changes after creation (BR-007).
final class DiaryEntry {
  const DiaryEntry._({
    required this.id,
    required this.entryDate,
    required this.meal,
    required this.snapshot,
    required this.quantity,
    required this.unit,
    required this.updatedAt,
    this.deletedAt,
  });

  /// A new entry. [quantity] is already validated by `parseQuantity`; the unit is checked here (BR-006).
  static EntryResult create({
    required String id,
    required LocalDate entryDate,
    required Meal meal,
    required ProductSnapshot snapshot,
    required double quantity,
    required EntryUnit unit,
    required DateTime updatedAt,
  }) {
    final error = _unitError(snapshot, unit);
    if (error != null) return EntryRejected(error);
    return EntryOk(
      DiaryEntry._(
        id: id,
        entryDate: entryDate,
        meal: meal,
        snapshot: snapshot,
        quantity: quantity,
        unit: unit,
        updatedAt: updatedAt,
      ),
    );
  }

  final String id;
  final LocalDate entryDate;
  final Meal meal;
  final ProductSnapshot snapshot;
  final double quantity;
  final EntryUnit unit;
  final DateTime updatedAt;

  /// Set by [delete]; a deleted entry is a tombstone for sync (PRD §13).
  final DateTime? deletedAt;

  Nutrition get nutrition => entryNutrition(snapshot, quantity, unit);

  /// Changes only quantity, unit, meal and date; the snapshot stays (FR-004 edge case, BR-007). The
  /// unit is checked again against the snapshot.
  EntryResult revise({
    required double quantity,
    required EntryUnit unit,
    required Meal meal,
    required LocalDate entryDate,
    required DateTime now,
  }) {
    final error = _unitError(snapshot, unit);
    if (error != null) return EntryRejected(error);
    return EntryOk(
      DiaryEntry._(
        id: id,
        entryDate: entryDate,
        meal: meal,
        snapshot: snapshot,
        quantity: quantity,
        unit: unit,
        updatedAt: now,
        deletedAt: deletedAt,
      ),
    );
  }

  /// A soft delete: [deletedAt] and [updatedAt] are [now] (PRD §13).
  DiaryEntry delete(DateTime now) => DiaryEntry._(
    id: id,
    entryDate: entryDate,
    meal: meal,
    snapshot: snapshot,
    quantity: quantity,
    unit: unit,
    updatedAt: now,
    deletedAt: now,
  );

  static EntryError? _unitError(ProductSnapshot snapshot, EntryUnit unit) {
    return switch (unit) {
      EntryUnit.serving =>
        snapshot.servingSize == null ? EntryError.servingUnavailable : null,
      EntryUnit.g =>
        snapshot.baseUnit == BaseUnit.g ? null : EntryError.unitMismatch,
      EntryUnit.ml =>
        snapshot.baseUnit == BaseUnit.ml ? null : EntryError.unitMismatch,
    };
  }
}
