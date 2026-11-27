import '../domain/auth_failure.dart';
import '../domain/email.dart';
import 'auth_gateway.dart';

/// Sends the password reset email (FR-001, PRD D-72). An invalid address never reaches the gateway.
class RequestPasswordReset {
  const RequestPasswordReset(this._gateway);

  final AuthGateway _gateway;

  Future<AuthResult> call(String rawEmail) async {
    final email = Email.tryParse(rawEmail);
    if (email == null) return const AuthError(InvalidEmail());
    return _gateway.requestPasswordReset(email);
  }
}
