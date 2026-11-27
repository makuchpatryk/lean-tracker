import '../domain/auth_failure.dart';
import '../domain/password.dart';
import 'auth_gateway.dart';

/// Stores the new password after the user opened the reset link (FR-001, PRD D-72).
class SetNewPassword {
  const SetNewPassword(this._gateway);

  final AuthGateway _gateway;

  Future<AuthResult> call(String rawPassword) async {
    final password = Password.tryParse(rawPassword);
    if (password == null) return const AuthError(PasswordTooShort());
    return _gateway.setNewPassword(password);
  }
}
