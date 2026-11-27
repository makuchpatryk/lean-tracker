import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/settings/settings.dart';

import '../../support/fakes.dart';

const goals = Goals(kcal: 2200, protein: 150, fat: 70, carbs: 240);
const other = Goals(kcal: 1800, protein: 120, fat: 60, carbs: 200);

void main() {
  late FakeGoalsRepository remote;
  late FakeGoalsCache cache;
  late CachingGoalsRepository repository;

  setUp(() {
    remote = FakeGoalsRepository();
    cache = FakeGoalsCache();
    repository = CachingGoalsRepository(remote, cache, 'user-a');
  });

  test('online goals are returned and cached', () async {
    remote.loadResult = const GoalsFound(goals);

    final result = await repository.load();

    expect((result as GoalsFound).goals, goals);
    expect(cache.goals['user-a'], goals);
  });

  test('offline with a cache returns the cached goals (BR-014)', () async {
    cache.goals['user-a'] = goals;
    remote.loadResult = const GoalsUnavailable();

    final result = await repository.load();

    expect((result as GoalsFound).goals, goals);
  });

  test('offline without a cache stays unavailable', () async {
    remote.loadResult = const GoalsUnavailable();

    expect(await repository.load(), isA<GoalsUnavailable>());
  });

  test("another user's cache is never used (BR-001)", () async {
    cache.goals['user-b'] = goals;
    remote.loadResult = const GoalsUnavailable();

    expect(await repository.load(), isA<GoalsUnavailable>());
  });

  test('missing goals clear the cache', () async {
    cache.goals['user-a'] = goals;
    remote.loadResult = const GoalsMissing();

    expect(await repository.load(), isA<GoalsMissing>());
    expect(cache.goals, isEmpty);
  });

  test('a saved goal set is cached', () async {
    await repository.save(other);

    expect(cache.goals['user-a'], other);
  });

  test(
    'a save that did not reach the API leaves the cache unchanged',
    () async {
      cache.goals['user-a'] = goals;
      remote.saveResult = const GoalsOffline();

      expect(await repository.save(other), isA<GoalsOffline>());
      expect(cache.goals['user-a'], goals);
    },
  );

  test(
    'a rejected save passes through and leaves the cache unchanged',
    () async {
      cache.goals['user-a'] = goals;
      remote.saveResult = const GoalsRejected();

      expect(await repository.save(other), isA<GoalsRejected>());
      expect(cache.goals['user-a'], goals);
    },
  );
}
