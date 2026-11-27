import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../auth/auth.dart';
import '../diary/diary.dart';
import '../gen/rest_client.dart';
import '../kernel/clock.dart';
import '../kernel/local_date.dart';
import '../kernel/uuid.dart';
import '../settings/settings.dart';
import 'config.dart';
import 'database.dart';
import 'http_client.dart';
import 'route_guard.dart';

/// Riverpod providers of the composition root (ARCHITECTURE AD9). The modules declare the providers
/// their screens need; this file plugs in the real adapters and derives what the router watches.

/// The real adapters, for the root `ProviderScope`. Tests build their own list with fakes.
List<Override> appOverrides() => [
  authGatewayProvider.overrideWith((ref) {
    final gateway = SupabaseAuthGateway(
      Supabase.instance.client.auth,
      AppConfig.authCallbackUrl,
    );
    ref.onDispose(gateway.dispose);
    return gateway;
  }),
  // The goals are cached on the device for the signed-in user, so the Diary opens offline (BR-014).
  goalsRepositoryProvider.overrideWith((ref) {
    final api = ApiGoalsRepository(ref.watch(restClientProvider).settings);
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return api;
    return CachingGoalsRepository(
      api,
      DriftGoalsCache(ref.watch(appDatabaseProvider)),
      userId,
    );
  }),
  // Rebuilt when the user changes, so a new user never reads the previous user's scope (BR-001).
  entryRepositoryProvider.overrideWith((ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const _SignedOutEntries();
    return DriftEntryRepository(ref.watch(appDatabaseProvider), userId);
  }),
  productSourceProvider.overrideWithValue(
    kDebugMode ? const DevSeedProductSource() : const NoProducts(),
  ),
  dailyGoalsProvider.overrideWith((ref) {
    final load = ref.watch(goalsProvider).value;
    return switch (load) {
      GoalsFound(:final goals) => DailyGoals(
        kcal: goals.kcal,
        protein: goals.protein,
        fat: goals.fat,
        carbs: goals.carbs,
      ),
      GoalsMissing() || GoalsUnavailable() || null => null,
    };
  }),
  clockProvider.overrideWithValue(const SystemClock()),
  uuidProvider.overrideWithValue(RandomUuid()),
];

/// The one device database, closed when the scope is disposed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

/// The signed-in user's id, or null. Follows the auth status, so it changes on sign-in and sign-out.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStatusProvider);
  return ref.watch(authGatewayProvider).currentUserId;
});

/// No products source in release builds: M3 has none (M4 adds the products module).
class NoProducts implements ProductSource {
  const NoProducts();

  @override
  List<ProductSnapshot> products() => const [];
}

/// Stands in while nobody is signed in, so a screen that is still on its way out never reads or writes
/// another user's rows (BR-001). It has no data and refuses every save.
class _SignedOutEntries implements EntryRepository {
  const _SignedOutEntries();

  @override
  Stream<List<DiaryEntry>> watchDay(LocalDate date) => Stream.value(const []);

  @override
  Future<DiaryEntry?> findById(String id) async => null;

  @override
  Future<SaveResult> save(DiaryEntry entry) async => const SaveFailed();
}

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
