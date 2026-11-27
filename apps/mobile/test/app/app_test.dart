import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/app/app.dart';
import 'package:lean_tracker/auth/auth.dart';
import 'package:lean_tracker/settings/settings.dart';
import 'package:lean_tracker/ui/tokens.dart';

import '../support/fakes.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  FakeAuthGateway? gateway,
  FakeGoalsRepository? goals,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authGatewayProvider.overrideWithValue(gateway ?? FakeAuthGateway()),
        goalsRepositoryProvider.overrideWithValue(
          goals ?? FakeGoalsRepository(),
        ),
      ],
      child: const LeanTrackerApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a signed-out user sees the login screen (UF-001)', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
  });

  testWidgets('a Polish system language shows Polish text (FR-017)', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('pl', 'PL')];

    await pumpApp(tester);

    expect(find.text('Zaloguj się'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('another system language falls back to English (FR-017)', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];

    await pumpApp(tester);

    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('a dark system theme uses the dark theme (FR-017)', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

    await pumpApp(tester);

    final theme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppPalette.dark.background);
  });

  testWidgets(
    'a signed-in user without goals is held on the goals gate (BP-006)',
    (tester) async {
      await pumpApp(
        tester,
        gateway: FakeAuthGateway(initial: AuthStatus.signedIn),
      );

      expect(find.text('Your daily goals'), findsOneWidget);
      expect(find.text('Diary arrives in the next version.'), findsNothing);
    },
  );

  testWidgets(
    'a signed-in user with goals lands on the Diary (FR-001 criterion 3)',
    (tester) async {
      await pumpApp(
        tester,
        gateway: FakeAuthGateway(initial: AuthStatus.signedIn),
        goals: FakeGoalsRepository(
          loadResult: const GoalsFound(
            Goals(kcal: 2200, protein: 150, fat: 70, carbs: 240),
          ),
        ),
      );

      expect(find.text('Diary arrives in the next version.'), findsOneWidget);
    },
  );

  testWidgets(
    'sign-up without a session shows the check-email screen (FR-001 criterion 1)',
    (tester) async {
      final gateway = FakeAuthGateway();
      await pumpApp(tester, gateway: gateway);

      gateway.emit(AuthStatus.awaitingConfirmation);
      await tester.pumpAndSettle();

      expect(find.text('Check your email'), findsOneWidget);
    },
  );
}
