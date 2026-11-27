import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../ui/theme.dart';
import 'router.dart';

/// Root widget: DESIGN themes that follow the system light or dark setting, PL and EN text from ARB
/// files with English as the fallback (FR-017).
class LeanTrackerApp extends ConsumerWidget {
  const LeanTrackerApp({super.key});

  static const supportedLocales = [Locale('en'), Locale('pl')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      // A system language other than Polish or English falls back to English (FR-017).
      localeResolutionCallback: (locale, supported) => supported.firstWhere(
        (s) => s.languageCode == locale?.languageCode,
        orElse: () => const Locale('en'),
      ),
    );
  }
}
