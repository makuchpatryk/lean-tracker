import 'dart:math';

/// Source of client-generated ids (PRD §13: `id` is a UUID v4). Injected so tests get fixed ids.
abstract interface class Uuid {
  String v4();
}

/// UUID v4 from a cryptographically secure random source.
final class RandomUuid implements Uuid {
  RandomUuid([Random? random]) : _random = random ?? Random.secure();

  final Random _random;

  @override
  String v4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
    String hex(int from, int to) => bytes
        .sublist(from, to)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
