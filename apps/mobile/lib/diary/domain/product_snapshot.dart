import 'units.dart';

/// Where a product's values came from (PRD §13 `source`).
enum EntrySource { off, own, manual }

/// The product facts an entry copies when it is saved (BR-007): name, base unit, per-100 values and
/// serving size. Later edits to the product never change an entry that holds a snapshot.
final class ProductSnapshot {
  const ProductSnapshot({
    required this.name,
    required this.baseUnit,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.fatPer100,
    required this.carbsPer100,
    required this.source,
    this.servingSize,
    this.sourceRef,
  });

  final String name;
  final BaseUnit baseUnit;
  final double kcalPer100;
  final double proteinPer100;
  final double fatPer100;
  final double carbsPer100;

  /// Size of one serving in [baseUnit], or null when the product has none.
  final double? servingSize;
  final EntrySource source;

  /// Barcode or other reference of the source, or null.
  final String? sourceRef;

  @override
  bool operator ==(Object other) =>
      other is ProductSnapshot &&
      other.name == name &&
      other.baseUnit == baseUnit &&
      other.kcalPer100 == kcalPer100 &&
      other.proteinPer100 == proteinPer100 &&
      other.fatPer100 == fatPer100 &&
      other.carbsPer100 == carbsPer100 &&
      other.servingSize == servingSize &&
      other.source == source &&
      other.sourceRef == sourceRef;

  @override
  int get hashCode => Object.hash(
    name,
    baseUnit,
    kcalPer100,
    proteinPer100,
    fatPer100,
    carbsPer100,
    servingSize,
    source,
    sourceRef,
  );
}
