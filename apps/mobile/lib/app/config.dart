/// Build-time configuration, read from `--dart-define-from-file=env/local.json` (git-ignored).
///
/// The app holds only the Supabase URL, the Supabase anon key and the API base URL. All three are
/// public by design: no service role key exists in the app (NFR-004, PRD §14).
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Deep link Supabase Auth redirects to after an email link or OAuth (PRD D-72). Registered in the
  /// Android manifest and in Info.plist, and allowed in the Auth redirect URLs.
  static const authCallbackUrl =
      'io.github.example.leantracker://auth-callback';

  /// Names of the keys that are not set. Never contains values.
  static List<String> get missingKeys => missingConfigKeys({
    'SUPABASE_URL': supabaseUrl,
    'SUPABASE_ANON_KEY': supabaseAnonKey,
    'API_BASE_URL': apiBaseUrl,
  });
}

/// Returns the names, in map order, whose value is empty. Only names leave this function, so a
/// message built from it cannot leak a value.
List<String> missingConfigKeys(Map<String, String> values) => [
  for (final entry in values.entries)
    if (entry.value.trim().isEmpty) entry.key,
];
