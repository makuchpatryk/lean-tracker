import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/auth/domain/auth_failure.dart';
import 'package:lean_tracker/auth/infrastructure/auth_error_mapping.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapAuthError reads the code, not the message', () {
    final cases = <String, Type>{
      'invalid_credentials': WrongCredentials,
      'email_not_confirmed': EmailNotConfirmed,
      'weak_password': PasswordTooShort,
      'user_already_exists': EmailAlreadyRegistered,
      'email_exists': EmailAlreadyRegistered,
    };
    for (final entry in cases.entries) {
      test('${entry.key} -> ${entry.value}', () {
        expect(mapAuthError(entry.key, '400').runtimeType, entry.value);
      });
    }

    test('an unknown code is UnknownAuthFailure', () {
      expect(mapAuthError('something_new', '500'), isA<UnknownAuthFailure>());
    });

    test('no code is UnknownAuthFailure', () {
      expect(mapAuthError(null, null), isA<UnknownAuthFailure>());
    });
  });

  group('mapAuthException', () {
    test('a socket error is NoConnection (UF-001 no network)', () {
      expect(
        mapAuthException(const SocketException('unreachable')),
        isA<NoConnection>(),
      );
    });

    test('a retryable fetch error is NoConnection', () {
      expect(
        mapAuthException(AuthRetryableFetchException()),
        isA<NoConnection>(),
      );
    });

    test('an AuthException is mapped by its code, not its message', () {
      expect(
        mapAuthException(
          const AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
            code: 'email_not_confirmed',
          ),
        ),
        isA<EmailNotConfirmed>(),
      );
    });

    test('any other error is UnknownAuthFailure', () {
      expect(mapAuthException(StateError('boom')), isA<UnknownAuthFailure>());
    });
  });

  group('isExistingUserSignUp', () {
    test('a user with no identities means already registered', () {
      expect(isExistingUserSignUp(0), isTrue);
    });

    test('a user with an identity is a new account', () {
      expect(isExistingUserSignUp(1), isFalse);
    });

    test('no user is not the existing-user signal', () {
      expect(isExistingUserSignUp(null), isFalse);
    });
  });
}
