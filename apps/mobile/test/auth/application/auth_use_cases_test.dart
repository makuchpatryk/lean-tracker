import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/auth/application/auth_gateway.dart';
import 'package:lean_tracker/auth/application/request_password_reset.dart';
import 'package:lean_tracker/auth/application/set_new_password.dart';
import 'package:lean_tracker/auth/application/sign_in.dart';
import 'package:lean_tracker/auth/application/sign_in_with_provider.dart';
import 'package:lean_tracker/auth/application/sign_out.dart';
import 'package:lean_tracker/auth/application/sign_up.dart';
import 'package:lean_tracker/auth/domain/auth_failure.dart';

import '../../support/fakes.dart';

void expectFailure<T extends AuthFailure>(AuthResult result) {
  expect(result, isA<AuthError>());
  expect((result as AuthError).failure, isA<T>());
}

void main() {
  late FakeAuthGateway gateway;
  setUp(() => gateway = FakeAuthGateway());

  group('SignUp', () {
    test(
      'a 7-character password never calls the gateway (FR-001 criterion 2)',
      () async {
        final result = await SignUp(gateway)('anna@example.com', '1234567');

        expectFailure<PasswordTooShort>(result);
        expect(gateway.calls, isEmpty);
      },
    );

    test('an invalid email never calls the gateway', () async {
      final result = await SignUp(gateway)('anna', '12345678');

      expectFailure<InvalidEmail>(result);
      expect(gateway.calls, isEmpty);
    });

    test('valid input reaches the gateway (FR-001 criterion 1)', () async {
      final result = await SignUp(gateway)('anna@example.com', '12345678');

      expect(result, isA<AuthOk>());
      expect(gateway.calls, ['signUp']);
    });

    test('EmailAlreadyRegistered passes through', () async {
      gateway.result = const AuthError(EmailAlreadyRegistered());

      final result = await SignUp(gateway)('anna@example.com', '12345678');

      expectFailure<EmailAlreadyRegistered>(result);
    });
  });

  group('SignIn', () {
    test('invalid input never calls the gateway', () async {
      expectFailure<InvalidEmail>(await SignIn(gateway)('', '12345678'));
      expectFailure<PasswordTooShort>(
        await SignIn(gateway)('anna@example.com', 'short'),
      );
      expect(gateway.calls, isEmpty);
    });

    test('WrongCredentials passes through', () async {
      gateway.result = const AuthError(WrongCredentials());

      expectFailure<WrongCredentials>(
        await SignIn(gateway)('anna@example.com', '12345678'),
      );
      expect(gateway.calls, ['signIn']);
    });
  });

  test('SignInWithProvider forwards the provider', () async {
    await SignInWithProvider(gateway)(SocialProvider.apple);

    expect(gateway.calls, ['signInWithProvider:apple']);
  });

  group('RequestPasswordReset', () {
    test('an invalid email never calls the gateway', () async {
      expectFailure<InvalidEmail>(await RequestPasswordReset(gateway)('nope'));
      expect(gateway.calls, isEmpty);
    });

    test('a valid email reaches the gateway', () async {
      await RequestPasswordReset(gateway)('anna@example.com');

      expect(gateway.calls, ['requestPasswordReset']);
    });
  });

  group('SetNewPassword', () {
    test('a short password never calls the gateway', () async {
      expectFailure<PasswordTooShort>(await SetNewPassword(gateway)('1234567'));
      expect(gateway.calls, isEmpty);
    });

    test('a valid password reaches the gateway', () async {
      await SetNewPassword(gateway)('12345678');

      expect(gateway.calls, ['setNewPassword']);
    });
  });

  test('SignOut calls the gateway', () async {
    await SignOut(gateway)();

    expect(gateway.calls, ['signOut']);
  });
}
