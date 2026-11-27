import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/app/route_guard.dart';
import 'package:lean_tracker/auth/auth.dart';

String? redirect(AuthStatus auth, GoalsStatus goals, String location) =>
    redirectFor(auth: auth, goals: goals, location: location);

void main() {
  group('loading', () {
    test('goes to /start', () {
      expect(
        redirect(AuthStatus.loading, GoalsStatus.unknown, '/diary'),
        '/start',
      );
    });
  });

  group('signedOut', () {
    test('login, forgot password and check email stay allowed', () {
      for (final path in ['/login', '/forgot-password', '/check-email']) {
        expect(
          redirect(AuthStatus.signedOut, GoalsStatus.unknown, path),
          isNull,
        );
      }
    });
    test('everything else goes to /login (the Diary is unreachable)', () {
      for (final path in [
        '/diary',
        '/settings',
        '/goals',
        '/start',
        '/new-password',
      ]) {
        expect(
          redirect(AuthStatus.signedOut, GoalsStatus.unknown, path),
          '/login',
        );
      }
    });
  });

  test('awaitingConfirmation goes to /check-email', () {
    expect(
      redirect(AuthStatus.awaitingConfirmation, GoalsStatus.unknown, '/login'),
      '/check-email',
    );
  });

  test('recovering is held on /new-password only', () {
    expect(
      redirect(AuthStatus.recovering, GoalsStatus.unknown, '/diary'),
      '/new-password',
    );
    expect(
      redirect(AuthStatus.recovering, GoalsStatus.unknown, '/login'),
      '/new-password',
    );
  });

  group('signedIn', () {
    test('goals unknown or unavailable hold on /start', () {
      for (final goals in [GoalsStatus.unknown, GoalsStatus.unavailable]) {
        expect(redirect(AuthStatus.signedIn, goals, '/diary'), '/start');
        expect(redirect(AuthStatus.signedIn, goals, '/start'), isNull);
      }
    });

    test('goals missing go to /goals from anywhere (BP-006)', () {
      for (final path in ['/diary', '/settings', '/start', '/login']) {
        expect(
          redirect(AuthStatus.signedIn, GoalsStatus.missing, path),
          '/goals',
        );
      }
      expect(
        redirect(AuthStatus.signedIn, GoalsStatus.missing, '/goals'),
        isNull,
      );
    });

    test('goals saved leave the entry screens for /diary', () {
      for (final path in [
        '/start',
        '/login',
        '/goals',
        '/check-email',
        '/forgot-password',
        '/new-password',
      ]) {
        expect(
          redirect(AuthStatus.signedIn, GoalsStatus.saved, path),
          '/diary',
        );
      }
    });

    test('goals saved leave the app screens alone', () {
      for (final path in ['/diary', '/settings', '/settings/goals']) {
        expect(redirect(AuthStatus.signedIn, GoalsStatus.saved, path), isNull);
      }
    });
  });

  test('a redirect target never redirects again (no loop)', () {
    const locations = [
      '/start',
      '/login',
      '/check-email',
      '/forgot-password',
      '/new-password',
      '/goals',
      '/auth-callback',
      '/diary',
      '/settings',
      '/settings/goals',
    ];
    for (final auth in AuthStatus.values) {
      for (final goals in GoalsStatus.values) {
        for (final location in locations) {
          final target = redirect(auth, goals, location);
          if (target == null) continue;
          expect(
            redirect(auth, goals, target),
            isNull,
            reason: '$auth/$goals: $location -> $target',
          );
        }
      }
    }
  });
}
