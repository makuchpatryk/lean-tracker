import 'auth_gateway.dart';

/// Signs in with Google or Apple through Supabase's browser OAuth (FR-001, PRD D-72).
class SignInWithProvider {
  const SignInWithProvider(this._gateway);

  final AuthGateway _gateway;

  Future<AuthResult> call(SocialProvider provider) =>
      _gateway.signInWithProvider(provider);
}
