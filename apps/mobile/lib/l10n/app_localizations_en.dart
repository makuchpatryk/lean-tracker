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
  String get retry => 'Try again';

  @override
  String get mascotLabel => 'Blueberry, the app mascot.';

  @override
  String get settingsEditGoals => 'Edit goals';

  @override
  String get diaryGreeting => 'Hi!';

  @override
  String get diaryKcalLeft => 'kcal left';

  @override
  String get diaryEaten => 'Eaten';

  @override
  String diaryOfGoal(String goal) {
    return 'of $goal kcal';
  }

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroFat => 'Fat';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String macroOfGoal(String value, String goal) {
    return '$value / $goal g';
  }

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack => 'Snacks';

  @override
  String mealSummary(String kcal, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$kcal kcal · $_temp0';
  }

  @override
  String get noEntries => 'No entries';

  @override
  String get mealKcalLabel => 'kcal in this meal';

  @override
  String entryLine(String quantity, String protein, String fat, String carbs) {
    return '$quantity · P $protein · F $fat · C $carbs';
  }

  @override
  String get addProduct => 'Add product';

  @override
  String addTo(String meal) {
    return 'Add to: $meal';
  }

  @override
  String get noProducts => 'No products yet';

  @override
  String per100(String kcal, String unit) {
    return '$kcal kcal / 100 $unit';
  }

  @override
  String servingInfo(String size, String unit) {
    return 'serving $size $unit';
  }

  @override
  String unitServingWithSize(String size, String unit) {
    return 'serving ($size $unit)';
  }

  @override
  String get unitMl => 'ml';

  @override
  String get quantityTitle => 'Quantity';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get mealLabel => 'Meal';

  @override
  String get dateLabel => 'Date';

  @override
  String get save => 'Save';

  @override
  String get errorQuantityRange => 'Enter a quantity from 0.1 to 10000.';

  @override
  String get errorEntryNotSaved => 'Could not save entry.';

  @override
  String get deleteEntry => 'Delete entry';

  @override
  String get deleteEntryQuestion => 'Delete this entry?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get a11yPreviousDay => 'Previous day';

  @override
  String get a11yNextDay => 'Next day';

  @override
  String get a11yPickDate => 'Pick a date';

  @override
  String a11yAddToMeal(String meal) {
    return 'Add entry to $meal';
  }

  @override
  String get a11yDecrease => 'Decrease quantity';

  @override
  String get a11yIncrease => 'Increase quantity';

  @override
  String get a11yNegative => 'minus';
}
