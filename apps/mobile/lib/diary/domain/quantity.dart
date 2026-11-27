import '../../kernel/limits/limits.dart';
import 'units.dart';

/// Result of [parseQuantity].
sealed class QuantityInput {
  const QuantityInput();
}

final class ValidQuantity extends QuantityInput {
  const ValidQuantity(this.value);

  final double value;
}

/// The text is not a quantity of 0.1 to 10000 with at most one decimal (BR-003). The UI maps it to a text.
final class InvalidQuantity extends QuantityInput {
  const InvalidQuantity();
}

final _quantityPattern = RegExp(r'^\d+([.,]\d)?$');

/// Validates the raw quantity text (BR-003, UF-003). `,` and `.` are both accepted as the separator.
/// More than one decimal and values outside [Limits.quantityMin]..[Limits.quantityMax] are rejected.
QuantityInput parseQuantity(String raw) {
  final text = raw.trim();
  if (!_quantityPattern.hasMatch(text)) return const InvalidQuantity();
  final value = _roundToOneDecimal(double.parse(text.replaceFirst(',', '.')));
  if (value < Limits.quantityMin || value > Limits.quantityMax) {
    return const InvalidQuantity();
  }
  return ValidQuantity(value);
}

/// The quantity after a − or + tap: ±10 for g and ml, ±1 for serving, kept inside the limits
/// ([direction] is -1 or 1).
double stepQuantity(double current, EntryUnit unit, int direction) {
  final step = unit == EntryUnit.serving ? 1 : 10;
  final moved = current + direction * step;
  return _roundToOneDecimal(
    moved.clamp(Limits.quantityMin, Limits.quantityMax).toDouble(),
  );
}

double _roundToOneDecimal(double value) => (value * 10).round() / 10;
