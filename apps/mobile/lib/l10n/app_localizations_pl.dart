// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Lean Tracker';

  @override
  String get loginTagline => 'Zapisuj posiłki szybko i na spokojnie.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Hasło (min. 8 znaków)';

  @override
  String get forgotPasswordLink => 'Nie pamiętasz hasła?';

  @override
  String get signInButton => 'Zaloguj się';

  @override
  String get signUpButton => 'Załóż konto';

  @override
  String get orDivider => 'lub';

  @override
  String get continueWithGoogle => 'Kontynuuj z Google';

  @override
  String get continueWithApple => 'Kontynuuj z Apple';

  @override
  String get errorInvalidEmail => 'Podaj poprawny adres e-mail.';

  @override
  String get errorPasswordTooShort => 'Hasło musi mieć co najmniej 8 znaków.';

  @override
  String get errorEmailTaken => 'Ten e-mail jest już zarejestrowany.';

  @override
  String get errorNoConnection => 'Brak połączenia. Spróbuj ponownie.';

  @override
  String get errorSocialSignIn =>
      'Logowanie nie powiodło się. Spróbuj ponownie.';

  @override
  String get errorWrongCredentials => 'Nieprawidłowy e-mail lub hasło.';

  @override
  String get errorEmailNotConfirmed =>
      'Najpierw potwierdź e-mail. Sprawdź skrzynkę.';

  @override
  String get errorUnknown => 'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get checkEmailTitle => 'Sprawdź skrzynkę';

  @override
  String get checkEmailBody =>
      'Sprawdź skrzynkę e-mail, aby potwierdzić konto. Otwórz link na tym telefonie.';

  @override
  String get backToSignIn => 'Wróć do logowania';

  @override
  String get resetTitle => 'Resetuj hasło';

  @override
  String get resetBody =>
      'Podaj e-mail. Wyślemy link do ustawienia nowego hasła.';

  @override
  String get resetSend => 'Wyślij link';

  @override
  String get resetSent => 'Sprawdź skrzynkę e-mail, aby zresetować hasło.';

  @override
  String get newPasswordTitle => 'Ustaw nowe hasło';

  @override
  String get newPasswordSave => 'Zapisz hasło';

  @override
  String get goalsTitle => 'Twoje dzienne cele';

  @override
  String get goalsSubtitle =>
      'Wpisz je ręcznie. Zmienisz je później w ustawieniach.';

  @override
  String get goalsMascot => 'Jestem Borówka. Zacznijmy od Twoich celów.';

  @override
  String get goalKcalLabel => 'Energia (500–10000)';

  @override
  String get goalProteinLabel => 'Białko (0–1000)';

  @override
  String get goalFatLabel => 'Tłuszcz (0–1000)';

  @override
  String get goalCarbsLabel => 'Węglowodany (0–1000)';

  @override
  String get unitKcal => 'kcal';

  @override
  String get unitGram => 'g';

  @override
  String get goalsSaveAndContinue => 'Zapisz i przejdź do dziennika';

  @override
  String get goalsSave => 'Zapisz';

  @override
  String get errorKcalRange => 'Podaj wartość od 500 do 10000.';

  @override
  String get errorMacroRange => 'Podaj wartość od 0 do 1000.';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsGoals => 'Cele';

  @override
  String get settingsEnergy => 'Energia';

  @override
  String get settingsMacros => 'Białko / tłuszcz / węgle';

  @override
  String get settingsLanguageTheme => 'Język i motyw';

  @override
  String get settingsFollowsSystem => 'Zgodnie z ustawieniami systemu.';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get navDiary => 'Dziennik';

  @override
  String get navSettings => 'Ustawienia';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get mascotLabel => 'Borówka, maskotka aplikacji.';

  @override
  String get settingsEditGoals => 'Edytuj cele';

  @override
  String get diaryGreeting => 'Cześć!';

  @override
  String get diaryKcalLeft => 'kcal zostało';

  @override
  String get diaryEaten => 'Zjedzone';

  @override
  String diaryOfGoal(String goal) {
    return 'z $goal kcal';
  }

  @override
  String get macroProtein => 'Białko';

  @override
  String get macroFat => 'Tłuszcz';

  @override
  String get macroCarbs => 'Węgle';

  @override
  String macroOfGoal(String value, String goal) {
    return '$value / $goal g';
  }

  @override
  String get mealBreakfast => 'Śniadanie';

  @override
  String get mealLunch => 'Obiad';

  @override
  String get mealDinner => 'Kolacja';

  @override
  String get mealSnack => 'Przekąski';

  @override
  String mealSummary(String kcal, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wpisu',
      many: '$count wpisów',
      few: '$count wpisy',
      one: '1 wpis',
    );
    return '$kcal kcal · $_temp0';
  }

  @override
  String get noEntries => 'Brak wpisów';

  @override
  String get mealKcalLabel => 'kcal w tym posiłku';

  @override
  String entryLine(String quantity, String protein, String fat, String carbs) {
    return '$quantity · B $protein · T $fat · W $carbs';
  }

  @override
  String get addProduct => 'Dodaj produkt';

  @override
  String addTo(String meal) {
    return 'Dodaj do: $meal';
  }

  @override
  String get noProducts => 'Brak produktów';

  @override
  String per100(String kcal, String unit) {
    return '$kcal kcal / 100 $unit';
  }

  @override
  String servingInfo(String size, String unit) {
    return 'porcja $size $unit';
  }

  @override
  String unitServingWithSize(String size, String unit) {
    return 'porcja ($size $unit)';
  }

  @override
  String get unitMl => 'ml';

  @override
  String get quantityTitle => 'Ilość';

  @override
  String get quantityLabel => 'Ilość';

  @override
  String get mealLabel => 'Posiłek';

  @override
  String get dateLabel => 'Data';

  @override
  String get save => 'Zapisz';

  @override
  String get errorQuantityRange => 'Podaj ilość od 0,1 do 10000.';

  @override
  String get errorEntryNotSaved => 'Nie udało się zapisać wpisu.';

  @override
  String get deleteEntry => 'Usuń wpis';

  @override
  String get deleteEntryQuestion => 'Usunąć ten wpis?';

  @override
  String get cancel => 'Anuluj';

  @override
  String get delete => 'Usuń';

  @override
  String get a11yPreviousDay => 'Poprzedni dzień';

  @override
  String get a11yNextDay => 'Następny dzień';

  @override
  String get a11yPickDate => 'Wybierz datę';

  @override
  String a11yAddToMeal(String meal) {
    return 'Dodaj wpis do: $meal';
  }

  @override
  String get a11yDecrease => 'Zmniejsz ilość';

  @override
  String get a11yIncrease => 'Zwiększ ilość';

  @override
  String get a11yNegative => 'minus';
}
