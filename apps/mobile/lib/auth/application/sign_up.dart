import '../domain/auth_failure.dart';
import '../domain/email.dart';
import '../domain/password.dart';
import 'auth_gateway.dart';

/// Creates an account with email and password (FR-001). Invalid input never reaches the gateway.
class SignUp {
  const SignUp(this._gateway);

  final AuthGateway _gateway;

  Future<AuthResult> call(String rawEmail, String rawPassword) async {
    final email = Email.tryParse(rawEmail);
    if (email == null) return const AuthError(InvalidEmail());
    final password = Password.tryParse(rawPassword);
    if (password == null) return const AuthError(PasswordTooShort());
    return _gateway.signUp(email, password);
  }
}
