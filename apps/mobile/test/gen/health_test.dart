import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/gen/export.dart';

void main() {
  test('generated Health reads status from JSON', () {
    final health = Health.fromJson({'status': 'ok'});

    expect(health.status, HealthStatus.ok);
  });

  test('generated Health round-trips JSON', () {
    for (final status in HealthStatus.$valuesDefined) {
      final json = Health(status: status).toJson();

      expect(Health.fromJson(json).status, status);
    }
  });

  test('generated Health maps an unknown status to the fallback value', () {
    final health = Health.fromJson({'status': 'degraded'});

    expect(health.status, HealthStatus.$unknown);
  });
}
