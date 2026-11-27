import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/app/app.dart';

void main() {
  testWidgets('shell builds with ProviderScope and go_router on one empty route',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LeanTrackerApp()));
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
