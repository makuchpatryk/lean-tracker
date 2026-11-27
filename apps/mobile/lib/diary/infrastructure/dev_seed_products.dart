import '../application/product_source.dart';
import '../domain/product_snapshot.dart';
import '../domain/units.dart';

/// Debug-only placeholder products, so M3 entries can be created before the products module exists.
/// The values are made up. Removed in M4, when [ProductSource] gets the real products (CODE_QUALITY:
/// known debt).
class DevSeedProductSource implements ProductSource {
  const DevSeedProductSource();

  static const _products = [
    // 200 kcal / 100 g, for the FR-004 example (150 g = 300 kcal).
    ProductSnapshot(
      name: 'Dev rice',
      baseUnit: BaseUnit.g,
      kcalPer100: 200,
      proteinPer100: 7,
      fatPer100: 1,
      carbsPer100: 44,
      source: EntrySource.manual,
    ),
    ProductSnapshot(
      name: 'Dev yogurt',
      baseUnit: BaseUnit.g,
      kcalPer100: 64,
      proteinPer100: 4.2,
      fatPer100: 3,
      carbsPer100: 4.4,
      servingSize: 150,
      source: EntrySource.manual,
    ),
    ProductSnapshot(
      name: 'Dev juice',
      baseUnit: BaseUnit.ml,
      kcalPer100: 42,
      proteinPer100: 0.5,
      fatPer100: 0.1,
      carbsPer100: 9.8,
      source: EntrySource.manual,
    ),
    ProductSnapshot(
      name: 'Dev bread',
      baseUnit: BaseUnit.g,
      kcalPer100: 250,
      proteinPer100: 8,
      fatPer100: 3,
      carbsPer100: 48,
      servingSize: 40,
      source: EntrySource.manual,
    ),
  ];

  @override
  List<ProductSnapshot> products() => _products;
}
