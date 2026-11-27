import '../../l10n/app_localizations.dart';
import '../domain/auth_failure.dart';

/// The only place an [AuthFailure] becomes user text (AD5). The switch is exhaustive: a new failure
/// does not compile until it has an ARB text.
String authFailureText(AppLocalizations l10n, AuthFailure failure) =>
    switch (failure) {
      InvalidEmail() => l10n.errorInvalidEmail,
      PasswordTooShort() => l10n.errorPasswordTooShort,
      EmailAlreadyRegistered() => l10n.errorEmailTaken,
      WrongCredentials() => l10n.errorWrongCredentials,
      EmailNotConfirmed() => l10n.errorEmailNotConfirmed,
      NoConnection() => l10n.errorNoConnection,
      SocialSignInFailed() => l10n.errorSocialSignIn,
      UnknownAuthFailure() => l10n.errorUnknown,
    };
