/// A syntactically valid email address, trimmed (FR-001). Whether it is registered is Supabase's call.
final class Email {
  const Email._(this.value);

  final String value;

  static final _shape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Returns the address, or null when the trimmed text is not shaped like an email.
  static Email? tryParse(String raw) {
    final trimmed = raw.trim();
    return _shape.hasMatch(trimmed) ? Email._(trimmed) : null;
  }

  /// Emails are never logged (CODE_QUALITY: security and privacy).
  @override
  String toString() => 'Email(…)';
}
