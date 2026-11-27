import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/auth/domain/email.dart';

void main() {
  test('a normal address is accepted and trimmed', () {
    expect(Email.tryParse('  anna@example.com ')?.value, 'anna@example.com');
  });

  test('malformed addresses are rejected (UF-001 error state)', () {
    for (final raw in [
      '',
      '   ',
      'anna',
      'anna@',
      '@example.com',
      'anna@example',
      'an na@example.com',
      'anna@@example.com',
    ]) {
      expect(Email.tryParse(raw), isNull, reason: '"$raw"');
    }
  });

  test('toString hides the address', () {
    expect(
      Email.tryParse('anna@example.com').toString(),
      isNot(contains('anna')),
    );
  });
}
