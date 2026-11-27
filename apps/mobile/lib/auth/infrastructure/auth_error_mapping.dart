import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_failure.dart';

/// Maps a Supabase Auth error code to an [AuthFailure]. The code is read, never the message text
/// (AD5). [statusCode] is accepted for logging-free symmetry with `AuthException` and is not needed
/// by any current rule.
AuthFailure mapAuthError(String? code, String? statusCode) => switch (code) {
  'invalid_credentials' => const WrongCredentials(),
  'email_not_confirmed' => const EmailNotConfirmed(),
  'weak_password' => const PasswordTooShort(),
  'user_already_exists' || 'email_exists' => const EmailAlreadyRegistered(),
  _ => const UnknownAuthFailure(),
};

/// Maps anything thrown by the SDK. An unreachable network is [NoConnection]; the rest goes by code.
AuthFailure mapAuthException(Object error) {
  if (error is SocketException || error is AuthRetryableFetchException) {
    return const NoConnection();
  }
  if (error is AuthException) return mapAuthError(error.code, error.statusCode);
  return const UnknownAuthFailure();
}

/// With email confirmation on, Supabase answers a sign-up for an existing email with a user that has
/// no identities and no error (it hides which emails are registered). That is "already registered".
bool isExistingUserSignUp(int? identitiesLength) => identitiesLength == 0;
