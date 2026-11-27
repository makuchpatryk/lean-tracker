import '../auth/auth.dart';

/// Where the user's goals stand, as the route guard sees it. `app/` maps the settings module's own
/// `GoalsLoad` to this, so settings never imports auth (AD3).
enum GoalsStatus { unknown, missing, saved, unavailable }

/// Route paths. The router and the guard share them.
abstract final class Routes {
  static const start = '/start';
  static const login = '/login';
  static const checkEmail = '/check-email';
  static const forgotPassword = '/forgot-password';
  static const newPassword = '/new-password';
  static const goals = '/goals';
  static const authCallback = '/auth-callback';
  static const diary = '/diary';
  static const settings = '/settings';
  static const editGoals = '/settings/goals';
}

/// Pure redirect rule of the router (PRD UF-001, BP-006). Returns the path to go to, or null to stay.
/// Redirecting to its own result returns null, so it cannot loop.
String? redirectFor({
  required AuthStatus auth,
  required GoalsStatus goals,
  required String location,
}) {
  String? goTo(String target) => location == target ? null : target;

  switch (auth) {
    case AuthStatus.loading:
      return goTo(Routes.start);
    case AuthStatus.signedOut:
      const open = {Routes.login, Routes.forgotPassword, Routes.checkEmail};
      return open.contains(location) ? null : Routes.login;
    case AuthStatus.awaitingConfirmation:
      return goTo(Routes.checkEmail);
    case AuthStatus.recovering:
      return goTo(Routes.newPassword);
    case AuthStatus.signedIn:
      switch (goals) {
        case GoalsStatus.unknown || GoalsStatus.unavailable:
          return goTo(Routes.start);
        case GoalsStatus.missing:
          // The Diary is unreachable until four goals are saved (BP-006).
          return goTo(Routes.goals);
        case GoalsStatus.saved:
          const entryScreens = {
            Routes.start,
            Routes.login,
            Routes.goals,
            Routes.checkEmail,
            Routes.forgotPassword,
            Routes.newPassword,
          };
          return entryScreens.contains(location) ? Routes.diary : null;
      }
  }
}
