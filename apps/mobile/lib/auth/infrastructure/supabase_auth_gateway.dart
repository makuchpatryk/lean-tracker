import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/auth_gateway.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_status.dart';
import '../domain/email.dart';
import '../domain/password.dart';
import 'auth_error_mapping.dart';

/// [AuthGateway] over Supabase Auth. It never logs emails, passwords or tokens.
class SupabaseAuthGateway implements AuthGateway {
  /// [callbackUrl] is the deep link the Auth emails and OAuth redirect to; the composition root passes
  /// it in, because a module never imports `app/`.
  SupabaseAuthGateway(this._auth, this._callbackUrl) {
    _current = _auth.currentSession == null
        ? AuthStatus.signedOut
        : AuthStatus.signedIn;
    _subscription = _auth.onAuthStateChange.listen(_onAuthState);
  }

  final GoTrueClient _auth;
  final String _callbackUrl;
  final _controller = StreamController<AuthStatus>.broadcast();
  late final StreamSubscription<AuthState> _subscription;
  late AuthStatus _current;

  @override
  Stream<AuthStatus> get status => _controller.stream;

  @override
  AuthStatus get current => _current;

  void dispose() {
    unawaited(_subscription.cancel());
    unawaited(_controller.close());
  }

  void _emit(AuthStatus next) {
    _current = next;
    _controller.add(next);
  }

  /// A recovery session stays "recovering" until the new password is stored or the user signs out, so a
  /// token refresh cannot drop the user out of the new-password screen.
  void _onAuthState(AuthState state) {
    final hasSession = state.session != null;
    switch (state.event) {
      case AuthChangeEvent.passwordRecovery:
        _emit(AuthStatus.recovering);
      case AuthChangeEvent.signedOut:
        _emit(AuthStatus.signedOut);
      case AuthChangeEvent.userUpdated:
        if (hasSession) _emit(AuthStatus.signedIn);
      case AuthChangeEvent.signedIn ||
          AuthChangeEvent.tokenRefreshed ||
          AuthChangeEvent.initialSession:
        if (hasSession && _current != AuthStatus.recovering) {
          _emit(AuthStatus.signedIn);
        } else if (!hasSession &&
            state.event == AuthChangeEvent.initialSession &&
            _current != AuthStatus.awaitingConfirmation) {
          _emit(AuthStatus.signedOut);
        }
      default:
        break;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return (await _auth.getSession())?.accessToken;
    } on AuthException {
      return null;
    }
  }

  @override
  Future<AuthResult> signUp(Email email, Password password) async {
    try {
      final response = await _auth.signUp(
        email: email.value,
        password: password.value,
        emailRedirectTo: _callbackUrl,
      );
      if (isExistingUserSignUp(response.user?.identities?.length)) {
        return const AuthError(EmailAlreadyRegistered());
      }
      if (response.session == null) _emit(AuthStatus.awaitingConfirmation);
      return const AuthOk();
    } on Exception catch (e) {
      return AuthError(mapAuthException(e));
    }
  }

  @override
  Future<AuthResult> signIn(Email email, Password password) async {
    try {
      await _auth.signInWithPassword(
        email: email.value,
        password: password.value,
      );
      return const AuthOk();
    } on Exception catch (e) {
      return AuthError(mapAuthException(e));
    }
  }

  @override
  Future<AuthResult> signInWithProvider(SocialProvider provider) async {
    try {
      final launched = await _auth.signInWithOAuth(switch (provider) {
        SocialProvider.google => OAuthProvider.google,
        SocialProvider.apple => OAuthProvider.apple,
      }, redirectTo: _callbackUrl);
      return launched ? const AuthOk() : const AuthError(SocialSignInFailed());
    } on Exception catch (e) {
      final failure = mapAuthException(e);
      return AuthError(
        failure is NoConnection ? failure : const SocialSignInFailed(),
      );
    }
  }

  @override
  Future<AuthResult> requestPasswordReset(Email email) async {
    try {
      await _auth.resetPasswordForEmail(email.value, redirectTo: _callbackUrl);
      return const AuthOk();
    } on Exception catch (e) {
      return AuthError(mapAuthException(e));
    }
  }

  @override
  Future<AuthResult> setNewPassword(Password password) async {
    try {
      await _auth.updateUser(UserAttributes(password: password.value));
      _emit(AuthStatus.signedIn);
      return const AuthOk();
    } on Exception catch (e) {
      return AuthError(mapAuthException(e));
    }
  }

  @override
  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      // No session (check-email "Back to sign in") emits no SDK event, so say it here.
      _emit(AuthStatus.signedOut);
      return const AuthOk();
    } on Exception catch (e) {
      return AuthError(mapAuthException(e));
    }
  }
}
