import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// App name in the title bar and task switcher.
  ///
  /// In en, this message translates to:
  /// **'Lean Tracker'**
  String get appTitle;

  /// Tagline under the logo on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Log meals fast and calmly.'**
  String get loginTagline;

  /// Label of the email field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Label of the password field; 8 is Limits.passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password (min. 8 characters)'**
  String get passwordLabel;

  /// Link on the login screen that opens the reset flow.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordLink;

  /// Primary button on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// Secondary button on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpButton;

  /// Divider between email sign-in and social sign-in.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// Google sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Apple sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// Shown under the email field for a malformed address (PRD UF-001).
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errorInvalidEmail;

  /// Shown when the password has fewer than 8 characters (FR-001).
  ///
  /// In en, this message translates to:
  /// **'Password must have at least 8 characters.'**
  String get errorPasswordTooShort;

  /// Shown when sign-up finds an existing account (PRD UF-001).
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get errorEmailTaken;

  /// Shown when the network is unreachable (PRD UF-001).
  ///
  /// In en, this message translates to:
  /// **'No connection. Try again.'**
  String get errorNoConnection;

  /// Shown when Google or Apple sign-in fails or is cancelled (PRD §15).
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Try again.'**
  String get errorSocialSignIn;

  /// Shown when sign-in credentials are rejected.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errorWrongCredentials;

  /// Shown when the account email is not confirmed yet.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email first. Check your inbox.'**
  String get errorEmailNotConfirmed;

  /// Fallback for an unexpected failure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorUnknown;

  /// Title of the check-email screen shown after sign-up.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmailTitle;

  /// Body of the check-email screen.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account. Open the link on this phone.'**
  String get checkEmailBody;

  /// Button that returns to the login screen.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// Title of the forgot-password screen.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetTitle;

  /// Explanation on the forgot-password screen.
  ///
  /// In en, this message translates to:
  /// **'Enter your email. We will send a link to set a new password.'**
  String get resetBody;

  /// Button that requests the reset email.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get resetSend;

  /// Confirmation after the reset email was requested.
  ///
  /// In en, this message translates to:
  /// **'Check your email to reset your password.'**
  String get resetSent;

  /// Title of the new-password screen opened from the reset link.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get newPasswordTitle;

  /// Button that stores the new password.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get newPasswordSave;

  /// Title of the goals screen.
  ///
  /// In en, this message translates to:
  /// **'Your daily goals'**
  String get goalsTitle;

  /// Subtitle of the onboarding goals screen.
  ///
  /// In en, this message translates to:
  /// **'Enter them manually. You can change them later in settings.'**
  String get goalsSubtitle;

  /// Mascot line on the onboarding goals screen.
  ///
  /// In en, this message translates to:
  /// **'I\'m Blueberry. Let\'s start with your goals.'**
  String get goalsMascot;

  /// Label of the energy goal field; the range is Limits.goalKcalMin..goalKcalMax.
  ///
  /// In en, this message translates to:
  /// **'Energy (500–10000)'**
  String get goalKcalLabel;

  /// Label of the protein goal field.
  ///
  /// In en, this message translates to:
  /// **'Protein (0–1000)'**
  String get goalProteinLabel;

  /// Label of the fat goal field.
  ///
  /// In en, this message translates to:
  /// **'Fat (0–1000)'**
  String get goalFatLabel;

  /// Label of the carbohydrates goal field.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates (0–1000)'**
  String get goalCarbsLabel;

  /// Unit suffix of the energy field.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get unitKcal;

  /// Unit suffix of the macro fields.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitGram;

  /// Button on the onboarding goals screen.
  ///
  /// In en, this message translates to:
  /// **'Save and go to diary'**
  String get goalsSaveAndContinue;

  /// Button on the edit goals screen.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get goalsSave;

  /// Shown when the energy goal is out of range (FR-002).
  ///
  /// In en, this message translates to:
  /// **'Enter a value from 500 to 10000.'**
  String get errorKcalRange;

  /// Shown when a macro goal is out of range.
  ///
  /// In en, this message translates to:
  /// **'Enter a value from 0 to 1000.'**
  String get errorMacroRange;

  /// Title of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section for the daily goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get settingsGoals;

  /// Energy row label in the goals summary.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get settingsEnergy;

  /// Macros row label in the goals summary.
  ///
  /// In en, this message translates to:
  /// **'Protein / fat / carbs'**
  String get settingsMacros;

  /// Settings row about language and theme.
  ///
  /// In en, this message translates to:
  /// **'Language and theme'**
  String get settingsLanguageTheme;

  /// Value of the language and theme row (FR-017).
  ///
  /// In en, this message translates to:
  /// **'Follows system settings.'**
  String get settingsFollowsSystem;

  /// Button that signs the user out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Bottom bar destination.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get navDiary;

  /// Bottom bar destination.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Temporary Diary body, removed in M3.
  ///
  /// In en, this message translates to:
  /// **'Diary arrives in the next version.'**
  String get diaryPlaceholder;

  /// Retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// Screen reader name of the mascot illustration.
  ///
  /// In en, this message translates to:
  /// **'Blueberry, the app mascot.'**
  String get mascotLabel;

  /// Screen reader label of the edit button in the Goals section of Settings.
  ///
  /// In en, this message translates to:
  /// **'Edit goals'**
  String get settingsEditGoals;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
