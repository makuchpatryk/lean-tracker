import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth.dart';
import '../diary/diary.dart';
import '../kernel/local_date.dart';
import '../settings/settings.dart';
import 'providers.dart';
import 'route_guard.dart';
import 'shell_scaffold.dart';
import 'start_screen.dart';

/// The router. The guard is the pure [redirectFor]; it is re-run whenever the auth status or the
/// goals status changes (PRD UF-001, BP-006).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(authStatusProvider, (_, _) => refresh.value++)
    ..listen(goalsStatusProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: Routes.start,
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(
      auth: ref.read(authStatusProvider).value ?? AuthStatus.loading,
      goals: ref.read(goalsStatusProvider),
      location: state.uri.path,
    ),
    routes: [
      GoRoute(path: Routes.start, builder: (_, _) => const StartScreen()),
      GoRoute(
        path: Routes.login,
        builder: (context, _) => LoginScreen(
          onForgotPassword: () => context.go(Routes.forgotPassword),
        ),
      ),
      GoRoute(
        path: Routes.checkEmail,
        builder: (_, _) => const CheckEmailScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, _) =>
            ForgotPasswordScreen(onBack: () => context.go(Routes.login)),
      ),
      GoRoute(
        path: Routes.newPassword,
        builder: (_, _) => const NewPasswordScreen(),
      ),
      GoRoute(path: Routes.goals, builder: (_, _) => const GoalsScreen()),
      // The custom-scheme link also reaches go_router, as "/" or "/auth-callback"; supabase_flutter
      // exchanges the code on its own, and the guard picks the screen once the session is known.
      GoRoute(path: '/', redirect: (_, _) => Routes.start),
      GoRoute(path: Routes.authCallback, redirect: (_, _) => Routes.start),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.diary,
                builder: (context, _) => DiaryScreen(
                  onOpenMeal: (meal, date) => context.go(
                    '${Routes.diaryMeal}/${meal.name}?date=${date.toIso()}',
                  ),
                  onAddEntry: (meal, date) => context.go(
                    '${Routes.diaryAdd}?meal=${meal.name}&date=${date.toIso()}',
                  ),
                ),
                routes: [
                  // Unknown meal or date values go back to the Diary (untrusted boundary).
                  GoRoute(
                    path: 'meal/:meal',
                    redirect: (_, state) =>
                        _mealAndDate(state) == null ? Routes.diary : null,
                    builder: (context, state) {
                      final params = _mealAndDate(state);
                      if (params == null) return const SizedBox.shrink();
                      final (:meal, :date) = params;
                      return MealDetailsScreen(
                        meal: meal,
                        date: date,
                        onAddProduct: () => context.go(
                          '${Routes.diaryAdd}?meal=${meal.name}&date=${date.toIso()}',
                        ),
                        onOpenEntry: (id) =>
                            context.go('${Routes.diaryEntry}/$id'),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'add',
                    redirect: (_, state) =>
                        _mealAndDate(state) == null ? Routes.diary : null,
                    builder: (context, state) {
                      final params = _mealAndDate(state);
                      if (params == null) return const SizedBox.shrink();
                      final (:meal, :date) = params;
                      return AddEntryScreen(
                        meal: meal,
                        date: date,
                        onPickProduct: (product) => context.go(
                          '${Routes.diaryAddQuantity}?meal=${meal.name}&date=${date.toIso()}',
                          extra: product,
                        ),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'quantity',
                        redirect: (_, state) =>
                            _mealAndDate(state) == null ||
                                state.extra is! ProductSnapshot
                            ? Routes.diary
                            : null,
                        builder: (_, state) {
                          final params = _mealAndDate(state);
                          final product = state.extra;
                          if (params == null || product is! ProductSnapshot) {
                            return const SizedBox.shrink();
                          }
                          return EntryFormScreen.create(
                            snapshot: product,
                            meal: params.meal,
                            date: params.date,
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'entry/:id',
                    builder: (_, state) => EntryFormScreen.edit(
                      entryId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, _) => SettingsScreen(
                  onEditGoals: () => context.go(Routes.editGoals),
                  onSignOut: () => ref.read(signOutProvider)(),
                ),
                routes: [
                  GoRoute(
                    path: 'goals',
                    builder: (context, _) => EditGoalsScreen(
                      onDone: () => context.go(Routes.settings),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// The `meal` (path or query) and `date` (query) of a Diary child route, or null when either is not a
/// known value. A redirect sends such a route to the Diary, so a builder only sees valid ones.
({Meal meal, LocalDate date})? _mealAndDate(GoRouterState state) {
  final meal = Meal.values.asNameMap()[state.pathParameters['meal'] ??
      state.uri.queryParameters['meal']];
  final date = LocalDate.parseIso(state.uri.queryParameters['date'] ?? '');
  if (meal == null || date == null) return null;
  return (meal: meal, date: date);
}
