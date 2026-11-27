import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/app/config.dart';

void main() {
  test('missingConfigKeys names only the empty keys, in order', () {
    final missing = missingConfigKeys({
      'SUPABASE_URL': 'http://10.0.2.2:54321',
      'SUPABASE_ANON_KEY': '',
      'API_BASE_URL': '  ',
    });

    expect(missing, ['SUPABASE_ANON_KEY', 'API_BASE_URL']);
  });

  test('missingConfigKeys never returns a value (NFR-004)', () {
    final missing = missingConfigKeys({
      'SUPABASE_URL': 'http://secret-host.example',
      'SUPABASE_ANON_KEY': '',
    });

    expect(missing.join(), isNot(contains('secret-host')));
  });

  test('AppConfig.missingKeys lists all three keys without dart-defines', () {
    expect(AppConfig.missingKeys, [
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
      'API_BASE_URL',
    ]);
  });

  test('auth callback URL is the registered deep link (PRD D-72)', () {
    expect(
      AppConfig.authCallbackUrl,
      'io.github.example.leantracker://auth-callback',
    );
  });
}
