import 'dart:async';

import 'package:lean_tracker/auth/auth.dart';
import 'package:lean_tracker/settings/settings.dart';

/// Records calls and answers with [result]. [emit] plays the part of the SDK's status stream.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    AuthStatus initial = AuthStatus.signedOut,
    this.result = const AuthOk(),
  }) : _current = initial;

  AuthResult result;
  final calls = <String>[];
  final _controller = StreamController<AuthStatus>.broadcast();
  AuthStatus _current;

  void emit(AuthStatus status) {
    _current = status;
    _controller.add(status);
  }

  @override
  Stream<AuthStatus> get status => _controller.stream;

  @override
  AuthStatus get current => _current;

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<AuthResult> signUp(Email email, Password password) async {
    calls.add('signUp');
    return result;
  }

  @override
  Future<AuthResult> signIn(Email email, Password password) async {
    calls.add('signIn');
    return result;
  }

  @override
  Future<AuthResult> signInWithProvider(SocialProvider provider) async {
    calls.add('signInWithProvider:${provider.name}');
    return result;
  }

  @override
  Future<AuthResult> requestPasswordReset(Email email) async {
    calls.add('requestPasswordReset');
    return result;
  }

  @override
  Future<AuthResult> setNewPassword(Password password) async {
    calls.add('setNewPassword');
    return result;
  }

  @override
  Future<AuthResult> signOut() async {
    calls.add('signOut');
    return result;
  }
}

class FakeGoalsRepository implements GoalsRepository {
  FakeGoalsRepository({this.loadResult = const GoalsMissing()});

  GoalsLoad loadResult;
  final saved = <Goals>[];

  @override
  Future<GoalsLoad> load() async => loadResult;

  @override
  Future<GoalsSave> save(Goals goals) async {
    saved.add(goals);
    return GoalsSaved(goals);
  }
}
