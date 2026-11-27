import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the Supabase session in the platform keystore (Android Keystore, iOS Keychain) instead of the
/// SDK's default SharedPreferences (PRD §14, D-74). The session string is never logged.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage([this._storage = const FlutterSecureStorage()]);

  static const _key = 'lean_tracker_supabase_session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}
