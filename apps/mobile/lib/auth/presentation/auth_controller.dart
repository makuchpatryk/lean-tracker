import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_gateway.dart';
import '../domain/auth_failure.dart';
import 'auth_providers.dart';

/// State shared by the auth screens: an action is running, the last failure, or the action succeeded
/// without changing the screen (a reset email was sent).
class AuthState {
  const AuthState({this.busy = false, this.failure, this.done = false});

  final bool busy;
  final AuthFailure? failure;
  final bool done;
}

/// View model of the login, forgot-password, check-email and new-password screens. Widgets send
/// intents; the use cases validate and call the gateway. A success that changes the session needs no
/// navigation here: the route guard follows the auth status.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> signIn(String email, String password) =>
      _run(() => ref.read(signInProvider)(email, password));

  Future<void> signUp(String email, String password) =>
      _run(() => ref.read(signUpProvider)(email, password));

  Future<void> signInWith(SocialProvider provider) =>
      _run(() => ref.read(signInWithProviderProvider)(provider));

  Future<void> requestPasswordReset(String email) =>
      _run(() => ref.read(requestPasswordResetProvider)(email));

  Future<void> setNewPassword(String password) =>
      _run(() => ref.read(setNewPasswordProvider)(password));

  Future<void> signOut() => _run(() => ref.read(signOutProvider)());

  Future<void> _run(Future<AuthResult> Function() action) async {
    state = const AuthState(busy: true);
    final result = await action();
    if (!ref.mounted) return;
    state = switch (result) {
      AuthOk() => const AuthState(done: true),
      AuthError(:final failure) => AuthState(failure: failure),
    };
  }
}

/// One controller per screen: the provider disposes with the screen.
final authControllerProvider =
    NotifierProvider.autoDispose<AuthController, AuthState>(AuthController.new);
