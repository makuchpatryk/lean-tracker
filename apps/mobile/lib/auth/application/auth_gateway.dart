import '../domain/auth_failure.dart';
import '../domain/auth_status.dart';
import '../domain/email.dart';
import '../domain/password.dart';

/// Social identity providers offered on the login screen (FR-001).
enum SocialProvider { google, apple }

/// Result of an auth action. Failures are values, never exceptions (CODE_QUALITY: errors).
sealed class AuthResult {
  const AuthResult();
}

final class AuthOk extends AuthResult {
  const AuthOk();
}

final class AuthError extends AuthResult {
  const AuthError(this.failure);

  final AuthFailure failure;
}

/// What the app needs from the identity service. Declared here, implemented in `infrastructure`
/// (Supabase Auth), so use cases and screens never see the SDK.
abstract interface class AuthGateway {
  /// Every change of [AuthStatus], after the first restored session.
  Stream<AuthStatus> get status;

  AuthStatus get current;

  /// The signed-in user's id, or null when signed out. Scopes the local data to one user (BR-001).
  String? get currentUserId;

  /// The current access token (refreshed by the SDK), or null when signed out.
  Future<String?> accessToken();

  Future<AuthResult> signUp(Email email, Password password);
  Future<AuthResult> signIn(Email email, Password password);
  Future<AuthResult> signInWithProvider(SocialProvider provider);
  Future<AuthResult> requestPasswordReset(Email email);
  Future<AuthResult> setNewPassword(Password password);
  Future<AuthResult> signOut();
}
