import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/diary/domain/quantity.dart';
import 'package:lean_tracker/diary/domain/units.dart';

double? valueOf(String raw) => switch (parseQuantity(raw)) {
  ValidQuantity(:final value) => value,
  InvalidQuantity() => null,
};

void main() {
  group('parseQuantity (BR-003)', () {
    test('accepts the limits and a decimal comma', () {
      expect(valueOf('0.1'), 0.1);
      expect(valueOf('10000'), 10000);
      expect(valueOf('1,5'), 1.5);
      expect(valueOf(' 150 '), 150);
    });

    test('rejects values outside 0.1 to 10000', () {
      for (final raw in ['0', '0.0', '10000.1', '10001', '-1']) {
        expect(valueOf(raw), isNull, reason: raw);
      }
    });

    test('rejects more than one decimal', () {
      expect(valueOf('1.25'), isNull);
      expect(valueOf('0,05'), isNull);
    });

    test('rejects empty and non-numbers', () {
      for (final raw in ['', '  ', 'abc', '1.2.3', '1,2,3', '1e3', '.5']) {
        expect(valueOf(raw), isNull, reason: raw);
      }
    });
  });

  group('stepQuantity', () {
    test('steps 10 for g and ml', () {
      expect(stepQuantity(100, EntryUnit.g, 1), 110);
      expect(stepQuantity(100, EntryUnit.ml, -1), 90);
    });

    test('steps 1 for serving', () {
      expect(stepQuantity(2, EntryUnit.serving, 1), 3);
      expect(stepQuantity(2, EntryUnit.serving, -1), 1);
    });

    test('is clamped to the limits', () {
      expect(stepQuantity(5, EntryUnit.g, -1), 0.1);
      expect(stepQuantity(9995, EntryUnit.g, 1), 10000);
      expect(stepQuantity(0.5, EntryUnit.serving, -1), 0.1);
    });

    test('keeps one decimal', () {
      expect(stepQuantity(1.5, EntryUnit.serving, 1), 2.5);
      expect(stepQuantity(0.1, EntryUnit.serving, 1), 1.1);
    });
  });
}
