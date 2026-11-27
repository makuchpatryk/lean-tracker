import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/domain/nutrition.dart';
import 'package:lean_tracker/diary/domain/units.dart';

import '../../support/diary_samples.dart';

void main() {
  test('150 g of a 200 kcal/100 g product is 300 kcal (FR-004)', () {
    final n = entryNutrition(plainProduct, 150, EntryUnit.g);

    expect(n.kcal, 300);
    expect(n.protein, 15);
    expect(n.fat, closeTo(7.5, 1e-9));
    expect(n.carbs, 45);
  });

  test('2 servings of a 30 g serving, 100 kcal/100 g, are 60 g and 60 kcal (FR-004)', () {
    expect(baseQuantity(servingProduct, 2, EntryUnit.serving), 60);
    expect(entryNutrition(servingProduct, 2, EntryUnit.serving).kcal, 60);
  });

  test('ml uses the same formula, with no conversion (BR-006)', () {
    final n = entryNutrition(juiceProduct, 250, EntryUnit.ml);

    expect(baseQuantity(juiceProduct, 250, EntryUnit.ml), 250);
    expect(n.kcal, 100);
    expect(n.carbs, 22.5);
  });

  test('values are not rounded', () {
    expect(entryNutrition(plainProduct, 0.1, EntryUnit.g).kcal, closeTo(0.2, 1e-9));
  });

  test('Nutrition adds field by field and zero is neutral', () {
    final sum = Nutrition.zero +
        entryNutrition(plainProduct, 100, EntryUnit.g) +
        entryNutrition(plainProduct, 50, EntryUnit.g);

    expect(sum.kcal, 300);
    expect(sum.protein, 15);
  });
}
