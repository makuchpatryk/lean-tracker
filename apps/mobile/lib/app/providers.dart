import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../auth/auth.dart';
import '../gen/rest_client.dart';
import '../settings/settings.dart';
import 'config.dart';
import 'http_client.dart';
import 'route_guard.dart';

/// Riverpod providers of the composition root (ARCHITECTURE AD9). The modules declare the providers
/// their screens need; this file plugs in the real adapters and derives what the router watches.

/// The real adapters, for the root `ProviderScope`. Tests build their own list with fakes.
List<Override> appOverrides() => [
  authGatewayProvider.overrideWith((ref) {
    final gateway = SupabaseAuthGateway(
      Supabase.instance.client.auth,
      callbackUrl: AppConfig.authCallbackUrl,
    );
    ref.onDispose(gateway.dispose);
    return gateway;
  }),
  goalsRepositoryProvider.overrideWith(
    (ref) => ApiGoalsRepository(ref.watch(restClientProvider).settings),
  ),
];

/// The current [AuthStatus], starting with the restored session and then following changes.
final authStatusProvider = StreamProvider<AuthStatus>((ref) async* {
  final gateway = ref.watch(authGatewayProvider);
  yield gateway.current;
  yield* gateway.status;
});

final dioProvider = Provider<Dio>(
  (ref) => createApiDio(
    ref.watch(authGatewayProvider),
    baseUrl: AppConfig.apiBaseUrl,
  ),
);

final restClientProvider = Provider<RestClient>(
  (ref) => RestClient(ref.watch(dioProvider)),
);

/// [GoalsStatus] for the route guard. Unknown until the user is signed in and the goals loaded. The
/// goals are loaded again whenever the auth status changes, so signing out and in as someone else
/// never shows the previous user's goals.
final goalsStatusProvider = Provider<GoalsStatus>((ref) {
  ref.listen(authStatusProvider, (previous, next) {
    if (previous?.value != next.value) ref.invalidate(goalsProvider);
  });
  final auth = ref.watch(authStatusProvider).value;
  if (auth != AuthStatus.signedIn) return GoalsStatus.unknown;
  final goals = ref.watch(goalsProvider);
  if (goals.isLoading && !goals.hasValue) return GoalsStatus.unknown;
  return switch (goals.value) {
    GoalsFound() => GoalsStatus.saved,
    GoalsMissing() => GoalsStatus.missing,
    GoalsUnavailable() || null => GoalsStatus.unavailable,
  };
});
