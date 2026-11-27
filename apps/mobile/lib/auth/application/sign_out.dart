import 'auth_gateway.dart';

/// Ends the session (UF-006).
class SignOut {
  const SignOut(this._gateway);

  final AuthGateway _gateway;

  Future<AuthResult> call() => _gateway.signOut();
}
