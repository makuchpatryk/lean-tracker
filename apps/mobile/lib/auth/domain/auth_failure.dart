/// Why an auth action failed. Inner layers return these; only presentation maps them to text (AD5).
sealed class AuthFailure {
  const AuthFailure();
}

/// The email is not shaped like an address.
final class InvalidEmail extends AuthFailure {
  const InvalidEmail();
}

/// The password has fewer than 8 characters.
final class PasswordTooShort extends AuthFailure {
  const PasswordTooShort();
}

/// Sign-up found an account with this email.
final class EmailAlreadyRegistered extends AuthFailure {
  const EmailAlreadyRegistered();
}

/// Email and password do not match an account.
final class WrongCredentials extends AuthFailure {
  const WrongCredentials();
}

/// The account exists but its email is not confirmed yet.
final class EmailNotConfirmed extends AuthFailure {
  const EmailNotConfirmed();
}

/// The network is unreachable.
final class NoConnection extends AuthFailure {
  const NoConnection();
}

/// Google or Apple sign-in failed or was cancelled.
final class SocialSignInFailed extends AuthFailure {
  const SocialSignInFailed();
}

/// Anything else. The cause is not shown to the user.
final class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure();
}
