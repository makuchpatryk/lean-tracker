import 'product_snapshot.dart';
import 'units.dart';

/// Energy and macros of an amount of food. Values are not rounded: the UI rounds once when it shows
/// them, so a sum of entries never drifts from its parts.
final class Nutrition {
  const Nutrition({
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  static const zero = Nutrition(kcal: 0, protein: 0, fat: 0, carbs: 0);

  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  Nutrition operator +(Nutrition other) => Nutrition(
    kcal: kcal + other.kcal,
    protein: protein + other.protein,
    fat: fat + other.fat,
    carbs: carbs + other.carbs,
  );
}

/// The amount in the product's base unit: `quantity × serving size` for `serving`, else [quantity]
/// (BR-006). g and ml are never converted into each other.
double baseQuantity(ProductSnapshot product, double quantity, EntryUnit unit) {
  final servingSize = product.servingSize;
  if (unit == EntryUnit.serving && servingSize != null) {
    return quantity * servingSize;
  }
  return quantity;
}

/// Nutrition of [quantity] [unit] of [product]: `value per 100 × base quantity / 100` (BR-006).
Nutrition entryNutrition(
  ProductSnapshot product,
  double quantity,
  EntryUnit unit,
) {
  final amount = baseQuantity(product, quantity, unit) / 100;
  return Nutrition(
    kcal: product.kcalPer100 * amount,
    protein: product.proteinPer100 * amount,
    fat: product.fatPer100 * amount,
    carbs: product.carbsPer100 * amount,
  );
}
