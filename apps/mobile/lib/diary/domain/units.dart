import 'product_snapshot.dart';

/// The unit a product's nutrition values are stated per 100 of (PRD §13 `base_unit`).
enum BaseUnit { g, ml }

/// The unit an entry's quantity is given in (BR-006).
enum EntryUnit { g, ml, serving }

/// The units an entry of [product] may use: its base unit, plus `serving` only when the product has
/// a serving size (BR-006).
List<EntryUnit> unitsFor(ProductSnapshot product) => [
  switch (product.baseUnit) {
    BaseUnit.g => EntryUnit.g,
    BaseUnit.ml => EntryUnit.ml,
  },
  if (product.servingSize != null) EntryUnit.serving,
];
