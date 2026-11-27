import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/kernel/uuid.dart';

void main() {
  final pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('v4 has the UUID text format, version 4 and variant 10xx (PRD §13)', () {
    final uuid = RandomUuid();

    for (var i = 0; i < 50; i++) {
      expect(uuid.v4(), matches(pattern));
    }
  });

  test('two calls differ', () {
    final uuid = RandomUuid();

    expect(uuid.v4(), isNot(uuid.v4()));
  });
}
