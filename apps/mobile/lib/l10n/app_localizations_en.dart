// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lean Tracker';

  @override
  String get loginTagline => 'Log meals fast and calmly.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password (min. 8 characters)';

  @override
  String get forgotPasswordLink => 'Forgot your password?';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signUpButton => 'Sign up';

  @override
  String get orDivider => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get errorInvalidEmail => 'Enter a valid email address.';

  @override
  String get errorPasswordTooShort =>
      'Password must have at least 8 characters.';

  @override
  String get errorEmailTaken => 'This email is already registered.';

  @override
  String get errorNoConnection => 'No connection. Try again.';

  @override
  String get errorSocialSignIn => 'Sign-in failed. Try again.';

  @override
  String get errorWrongCredentials => 'Wrong email or password.';

  @override
  String get errorEmailNotConfirmed =>
      'Confirm your email first. Check your inbox.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String get checkEmailTitle => 'Check your email';

  @override
  String get checkEmailBody =>
      'Check your email to confirm your account. Open the link on this phone.';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get resetTitle => 'Reset password';

  @override
  String get resetBody =>
      'Enter your email. We will send a link to set a new password.';

  @override
  String get resetSend => 'Send link';

  @override
  String get resetSent => 'Check your email to reset your password.';

  @override
  String get newPasswordTitle => 'Set a new password';

  @override
  String get newPasswordSave => 'Save password';

  @override
  String get goalsTitle => 'Your daily goals';

  @override
  String get goalsSubtitle =>
      'Enter them manually. You can change them later in settings.';

  @override
  String get goalsMascot => 'I\'m Blueberry. Let\'s start with your goals.';

  @override
  String get goalKcalLabel => 'Energy (500–10000)';

  @override
  String get goalProteinLabel => 'Protein (0–1000)';

  @override
  String get goalFatLabel => 'Fat (0–1000)';

  @override
  String get goalCarbsLabel => 'Carbohydrates (0–1000)';

  @override
  String get unitKcal => 'kcal';

  @override
  String get unitGram => 'g';

  @override
  String get goalsSaveAndContinue => 'Save and go to diary';

  @override
  String get goalsSave => 'Save';

  @override
  String get errorKcalRange => 'Enter a value from 500 to 10000.';

  @override
  String get errorMacroRange => 'Enter a value from 0 to 1000.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGoals => 'Goals';

  @override
  String get settingsEnergy => 'Energy';

  @override
  String get settingsMacros => 'Protein / fat / carbs';

  @override
  String get settingsLanguageTheme => 'Language and theme';

  @override
  String get settingsFollowsSystem => 'Follows system settings.';

  @override
  String get signOut => 'Sign out';

  @override
  String get navDiary => 'Diary';

  @override
  String get navSettings => 'Settings';

  @override
  String get diaryPlaceholder => 'Diary arrives in the next version.';

  @override
  String get retry => 'Try again';

  @override
  String get mascotLabel => 'Blueberry, the app mascot.';

  @override
  String get settingsEditGoals => 'Edit goals';
}
