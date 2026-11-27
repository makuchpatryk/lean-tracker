import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/auth/domain/password.dart';

void main() {
  test('7 characters are rejected (FR-001 criterion 2)', () {
    expect(Password.tryParse('1234567'), isNull);
  });

  test('8 characters are accepted (FR-001 criterion 1)', () {
    expect(Password.tryParse('12345678')?.value, '12345678');
  });

  test('an empty password is rejected', () {
    expect(Password.tryParse(''), isNull);
  });

  test('spaces count and are kept', () {
    expect(Password.tryParse('       a')?.value, '       a');
  });

  test('characters are counted, not UTF-16 units', () {
    // 7 emoji are 14 UTF-16 units but 7 characters.
    expect(Password.tryParse('😀😀😀😀😀😀😀'), isNull);
    expect(Password.tryParse('😀😀😀😀😀😀😀😀'), isNotNull);
  });

  test('toString hides the password', () {
    expect(
      Password.tryParse('secret-pass').toString(),
      isNot(contains('secret')),
    );
  });
}
