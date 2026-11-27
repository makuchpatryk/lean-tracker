import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/goals_repository.dart';
import '../application/load_goals.dart';
import '../application/save_goals.dart';
import '../domain/goals.dart';

/// Where the goals live. `app/` overrides this with the API repository (composition root), and tests
/// override it with a fake.
final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => throw UnimplementedError(
    'Override goalsRepositoryProvider in the ProviderScope.',
  ),
);

final loadGoalsProvider = Provider(
  (ref) => LoadGoals(ref.watch(goalsRepositoryProvider)),
);
final saveGoalsProvider = Provider(
  (ref) => SaveGoals(ref.watch(goalsRepositoryProvider)),
);

/// The signed-in user's goals. `app/` invalidates it when the user signs in or out, so one user's goals
/// are never shown to the next.
final goalsProvider = AsyncNotifierProvider<GoalsNotifier, GoalsLoad>(
  GoalsNotifier.new,
);

class GoalsNotifier extends AsyncNotifier<GoalsLoad> {
  @override
  Future<GoalsLoad> build() => ref.read(loadGoalsProvider)();

  /// Saves the form values. A stored result replaces the loaded goals, which lets the route guard
  /// open the Diary (BP-006).
  Future<GoalsSave> save(Map<GoalField, String> raw) async {
    final result = await ref.read(saveGoalsProvider)(raw);
    if (ref.mounted && result is GoalsSaved) {
      state = AsyncData(GoalsFound(result.goals));
    }
    return result;
  }

  /// Loads again after a failed load ("Try again" on /start).
  Future<void> retry() async {
    state = const AsyncLoading();
    final result = await ref.read(loadGoalsProvider)();
    if (ref.mounted) state = AsyncData(result);
  }
}
