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

  /// Greeting at the top of the Diary.
  ///
  /// In en, this message translates to:
  /// **'Hi!'**
  String get diaryGreeting;

  /// Label under the remaining kcal on the Diary summary card.
  ///
  /// In en, this message translates to:
  /// **'kcal left'**
  String get diaryKcalLeft;

  /// Label of the consumed kcal on the Diary summary card.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get diaryEaten;

  /// Consumed kcal compared to the goal; {goal} is the formatted kcal goal.
  ///
  /// In en, this message translates to:
  /// **'of {goal} kcal'**
  String diaryOfGoal(String goal);

  /// Protein label.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get macroProtein;

  /// Fat label.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get macroFat;

  /// Carbohydrates label.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get macroCarbs;

  /// Consumed grams of a macro over its goal, both formatted.
  ///
  /// In en, this message translates to:
  /// **'{value} / {goal} g'**
  String macroOfGoal(String value, String goal);

  /// Meal name (BR-005).
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// Meal name (BR-005).
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// Meal name (BR-005).
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// Meal name (BR-005).
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get mealSnack;

  /// Meal card summary: formatted kcal and the number of entries.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · {count, plural, one{1 entry} other{{count} entries}}'**
  String mealSummary(String kcal, int count);

  /// Shown for a meal without entries (PRD UF-002).
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get noEntries;

  /// Label under the kcal total on Meal details.
  ///
  /// In en, this message translates to:
  /// **'kcal in this meal'**
  String get mealKcalLabel;

  /// Entry line: formatted quantity with unit, then protein, fat and carbs in grams.
  ///
  /// In en, this message translates to:
  /// **'{quantity} · P {protein} · F {fat} · C {carbs}'**
  String entryLine(String quantity, String protein, String fat, String carbs);

  /// Button on Meal details that opens Add entry.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// Header of the Add entry screen; {meal} is the meal name.
  ///
  /// In en, this message translates to:
  /// **'Add to: {meal}'**
  String addTo(String meal);

  /// Shown on Add entry when there is no product source (M3 release builds).
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProducts;

  /// Energy per 100 g or ml of a product.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal / 100 {unit}'**
  String per100(String kcal, String unit);

  /// Serving size of a product.
  ///
  /// In en, this message translates to:
  /// **'serving {size} {unit}'**
  String servingInfo(String size, String unit);

  /// Serving unit chip with its size.
  ///
  /// In en, this message translates to:
  /// **'serving ({size} {unit})'**
  String unitServingWithSize(String size, String unit);

  /// Unit: milliliter.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMl;

  /// Title of the quantity form.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityTitle;

  /// Label of the quantity field.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// Label of the meal chips on the quantity form.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get mealLabel;

  /// Label of the date field on the quantity form.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// Save button of the quantity form.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Shown under the quantity field when it is invalid (PRD UF-003, BR-003).
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity from 0.1 to 10000.'**
  String get errorQuantityRange;

  /// SnackBar when an entry could not be stored (PRD UF-002).
  ///
  /// In en, this message translates to:
  /// **'Could not save entry.'**
  String get errorEntryNotSaved;

  /// Button that deletes an entry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntry;

  /// Question of the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntryQuestion;

  /// Cancel button of a dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button of the delete dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Screen reader label of the previous-day arrow.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get a11yPreviousDay;

  /// Screen reader label of the next-day arrow.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get a11yNextDay;

  /// Screen reader label of the calendar button.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get a11yPickDate;

  /// Screen reader label of a meal's plus button.
  ///
  /// In en, this message translates to:
  /// **'Add entry to {meal}'**
  String a11yAddToMeal(String meal);

  /// Screen reader label of the minus button.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get a11yDecrease;

  /// Screen reader label of the plus button.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get a11yIncrease;

  /// Spoken in place of the minus sign before a negative number.
  ///
  /// In en, this message translates to:
  /// **'minus'**
  String get a11yNegative;
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
