import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/kernel/local_date.dart';

void main() {
  test('23:59:59 and 00:00 local are different days (BR-004)', () {
    final late = LocalDate.of(DateTime(2026, 11, 25, 23, 59, 59));
    final early = LocalDate.of(DateTime(2026, 11, 26, 0, 0));

    expect(late, const LocalDate(2026, 11, 25));
    expect(early, const LocalDate(2026, 11, 26));
    expect(late, isNot(early));
  });

  test('the day follows the local fields, not the UTC instant (BR-004)', () {
    final local = DateTime(2026, 11, 25, 0, 30);

    expect(LocalDate.of(local), const LocalDate(2026, 11, 25));
  });

  group('addDays', () {
    test('crosses a month end', () {
      expect(const LocalDate(2026, 1, 31).addDays(1), const LocalDate(2026, 2, 1));
      expect(const LocalDate(2026, 3, 1).addDays(-1), const LocalDate(2026, 2, 28));
    });

    test('crosses a year end', () {
      expect(const LocalDate(2026, 12, 31).addDays(1), const LocalDate(2027, 1, 1));
      expect(const LocalDate(2027, 1, 1).addDays(-1), const LocalDate(2026, 12, 31));
    });

    test('handles a leap day', () {
      expect(const LocalDate(2028, 2, 28).addDays(1), const LocalDate(2028, 2, 29));
    });

    test('moves exactly one day over a DST change', () {
      // Europe spring-forward 2026-03-29 and fall-back 2026-10-25: the date still moves by one.
      expect(const LocalDate(2026, 3, 28).addDays(1), const LocalDate(2026, 3, 29));
      expect(const LocalDate(2026, 3, 29).addDays(1), const LocalDate(2026, 3, 30));
      expect(const LocalDate(2026, 10, 24).addDays(1), const LocalDate(2026, 10, 25));
      expect(const LocalDate(2026, 10, 25).addDays(1), const LocalDate(2026, 10, 26));
    });
  });

  group('ISO form', () {
    test('round trips and pads', () {
      const date = LocalDate(2026, 3, 5);

      expect(date.toIso(), '2026-03-05');
      expect(LocalDate.parseIso(date.toIso()), date);
    });

    test('rejects text that is not a real day', () {
      for (final text in ['', '2026-3-5', '2026-02-30', '2026-13-01', 'abc', '2026-11-25T10:00']) {
        expect(LocalDate.parseIso(text), isNull, reason: text);
      }
    });
  });

  test('compares by year, month, then day', () {
    expect(const LocalDate(2026, 11, 25).compareTo(const LocalDate(2026, 11, 26)), isNegative);
    expect(const LocalDate(2027, 1, 1).compareTo(const LocalDate(2026, 12, 31)), isPositive);
    expect(const LocalDate(2026, 5, 1).compareTo(const LocalDate(2026, 4, 30)), isPositive);
    expect(const LocalDate(2026, 5, 1).compareTo(const LocalDate(2026, 5, 1)), isZero);
    expect(const LocalDate(2026, 5, 1).hashCode, const LocalDate(2026, 5, 1).hashCode);
  });
}
