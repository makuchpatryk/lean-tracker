import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth.dart';
import '../ui/theme.dart';
import 'app.dart';
import 'config.dart';
import 'providers.dart';

/// Starts the app: checks the build-time config, restores the session from secure storage (PKCE
/// flow, FR-001 criterion 3), then runs [LeanTrackerApp].
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final missing = AppConfig.missingKeys;
  if (missing.isNotEmpty) {
    runApp(ConfigErrorApp(missingKeys: missing));
    return;
  }
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      localStorage: SecureSessionStorage(),
    ),
  );
  runApp(
    ProviderScope(overrides: appOverrides(), child: const LeanTrackerApp()),
  );
}

/// Developer-only screen for a build without `--dart-define-from-file`. It is never shown to users
/// of a configured build, so its text is fixed English and names keys, never values.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.missingKeys, super.key});

  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Missing build configuration: ${missingKeys.join(', ')}.\n'
              'Run with --dart-define-from-file=env/local.json (see env/example.json).',
            ),
          ),
        ),
      ),
    );
  }
}
