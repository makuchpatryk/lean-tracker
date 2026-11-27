import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../domain/diary_entry.dart';
import '../domain/meal.dart';
import '../domain/nutrition.dart';
import '../domain/product_snapshot.dart';
import '../domain/units.dart';

/// The one place that rounds and formats diary numbers and texts (CODE_QUALITY: DRY). The domain keeps
/// unrounded values; rounding happens here, once, when a value is shown.
class DiaryFormat {
  DiaryFormat(this.l10n)
    : _whole = NumberFormat.decimalPattern(l10n.localeName),
      _oneDecimal = NumberFormat.decimalPatternDigits(
        locale: l10n.localeName,
        decimalDigits: 1,
      ),
      _quantity = NumberFormat('#,##0.#', l10n.localeName),
      _field = NumberFormat('0.#', l10n.localeName);

  final AppLocalizations l10n;
  final NumberFormat _whole;
  final NumberFormat _oneDecimal;
  final NumberFormat _quantity;
  final NumberFormat _field;

  /// kcal and macros in summaries and entry lines: rounded to a whole number ("2 200").
  String whole(double value) => _whole.format(value.round());

  /// The live preview of the quantity form: one decimal ("6,2").
  String oneDecimal(double value) => _oneDecimal.format(value);

  String goal(int value) => _whole.format(value);

  /// A quantity with at most one decimal ("150", "1,5").
  String quantity(double value) => _quantity.format(value);

  /// The quantity as typed in the form field: no grouping, at most one decimal.
  String fieldText(double value) => _field.format(value);

  /// Remaining kcal. Over the goal it is negative and shows the minus sign U+2212, not a hyphen.
  String remaining(double kcal) {
    final rounded = kcal.round();
    return rounded < 0 ? '−${_whole.format(-rounded)}' : _whole.format(rounded);
  }

  /// What a screen reader says for [remaining]: "minus 120", never a symbol it may skip.
  String remainingSpoken(double kcal) {
    final rounded = kcal.round();
    return rounded < 0 ? '${l10n.a11yNegative} ${_whole.format(-rounded)}' : _whole.format(rounded);
  }

  String mealName(Meal meal) => switch (meal) {
    Meal.breakfast => l10n.mealBreakfast,
    Meal.lunch => l10n.mealLunch,
    Meal.dinner => l10n.mealDinner,
    Meal.snack => l10n.mealSnack,
  };

  String baseUnit(BaseUnit unit) => switch (unit) {
    BaseUnit.g => l10n.unitGram,
    BaseUnit.ml => l10n.unitMl,
  };

  /// A unit as a chip or a suffix. `serving` carries the size of one serving of [snapshot].
  String unit(EntryUnit unit, ProductSnapshot snapshot) => switch (unit) {
    EntryUnit.g => l10n.unitGram,
    EntryUnit.ml => l10n.unitMl,
    EntryUnit.serving => l10n.unitServingWithSize(
      quantity(snapshot.servingSize ?? 0),
      baseUnit(snapshot.baseUnit),
    ),
  };

  /// "150 g", or "2 serving (30 g)".
  String quantityWithUnit(DiaryEntry entry) =>
      '${quantity(entry.quantity)} ${unit(entry.unit, entry.snapshot)}';

  /// "150 g · P 18 · F 0 · C 6", the board's entry line.
  String entryLine(DiaryEntry entry) {
    final n = entry.nutrition;
    return l10n.entryLine(
      quantityWithUnit(entry),
      whole(n.protein),
      whole(n.fat),
      whole(n.carbs),
    );
  }

  /// "64 kcal / 100 g", plus " · serving 150 g" when the product has a serving size.
  String productInfo(ProductSnapshot product) {
    final base = baseUnit(product.baseUnit);
    final per100 = l10n.per100(whole(product.kcalPer100), base);
    final serving = product.servingSize;
    if (serving == null) return per100;
    return '$per100 · ${l10n.servingInfo(quantity(serving), base)}';
  }

  /// "319 kcal · 2 entries".
  String mealSummary(Nutrition total, int count) =>
      l10n.mealSummary(whole(total.kcal), count);

  /// "96 kcal".
  String kcal(double value) => '${whole(value)} ${l10n.unitKcal}';
}
