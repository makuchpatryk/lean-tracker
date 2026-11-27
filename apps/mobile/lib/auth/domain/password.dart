import '../../kernel/limits/limits.dart';

/// A password of at least [Limits.passwordMinLength] characters (FR-001, D-41). Not trimmed: spaces
/// count, because the user may have chosen them.
final class Password {
  const Password._(this.value);

  final String value;

  /// Returns the password, or null when it is shorter than the minimum (7 characters fail, 8 pass).
  static Password? tryParse(String raw) =>
      raw.runes.length >= Limits.passwordMinLength ? Password._(raw) : null;

  /// Passwords are never logged (CODE_QUALITY: security and privacy).
  @override
  String toString() => 'Password(…)';
}
