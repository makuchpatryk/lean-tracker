import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/app/app.dart';
import 'package:lean_tracker/auth/auth.dart';
import 'package:lean_tracker/settings/settings.dart';

import '../../support/fakes.dart';

Future<FakeAuthGateway> pumpLogin(
  WidgetTester tester, {
  AuthResult result = const AuthOk(),
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final gateway = FakeAuthGateway(result: result);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authGatewayProvider.overrideWithValue(gateway),
        goalsRepositoryProvider.overrideWithValue(FakeGoalsRepository()),
      ],
      child: const LeanTrackerApp(),
    ),
  );
  await tester.pumpAndSettle();
  return gateway;
}

Future<void> submit(
  WidgetTester tester, {
  required String email,
  required String password,
  required String button,
}) async {
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, button));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a 7-character password shows the length error and calls nothing (FR-001 criterion 2)',
    (tester) async {
      final gateway = await pumpLogin(tester);

      await submit(
        tester,
        email: 'anna@example.com',
        password: '1234567',
        button: 'Sign up',
      );

      expect(
        find.text('Password must have at least 8 characters.'),
        findsOneWidget,
      );
      expect(gateway.calls, isEmpty);
    },
  );

  testWidgets('an invalid email shows the email error', (tester) async {
    await pumpLogin(tester);

    await submit(
      tester,
      email: 'anna',
      password: '12345678',
      button: 'Sign in',
    );

    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('an already registered email shows its error (UF-001)', (
    tester,
  ) async {
    final gateway = await pumpLogin(
      tester,
      result: const AuthError(EmailAlreadyRegistered()),
    );

    await submit(
      tester,
      email: 'anna@example.com',
      password: '12345678',
      button: 'Sign up',
    );

    expect(find.text('This email is already registered.'), findsOneWidget);
    expect(gateway.calls, ['signUp']);
  });

  testWidgets('no network shows the connection error (UF-001)', (tester) async {
    await pumpLogin(tester, result: const AuthError(NoConnection()));

    await submit(
      tester,
      email: 'anna@example.com',
      password: '12345678',
      button: 'Sign in',
    );

    expect(find.text('No connection. Try again.'), findsOneWidget);
  });
}
