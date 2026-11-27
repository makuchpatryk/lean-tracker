import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/app/database.dart';
import 'package:lean_tracker/settings/settings.dart';

const goals = Goals(kcal: 2200, protein: 150, fat: 70, carbs: 240);
const other = Goals(kcal: 1800, protein: 120, fat: 60, carbs: 200);

void main() {
  late AppDatabase db;
  late DriftGoalsCache cache;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = DriftGoalsCache(db);
  });

  tearDown(() => db.close());

  test('reads nothing before a write', () async {
    expect(await cache.read('user-a'), isNull);
  });

  test('writes and reads the four goals', () async {
    await cache.write('user-a', goals);

    expect(await cache.read('user-a'), goals);
  });

  test('a second write updates the same row (upsert)', () async {
    await cache.write('user-a', goals);
    await cache.write('user-a', other);

    expect(await cache.read('user-a'), other);
  });

  test('clear removes the goals', () async {
    await cache.write('user-a', goals);

    await cache.clear('user-a');

    expect(await cache.read('user-a'), isNull);
  });

  test('users are isolated (BR-001)', () async {
    await cache.write('user-a', goals);
    await cache.write('user-b', other);

    expect(await cache.read('user-a'), goals);
    expect(await cache.read('user-b'), other);

    await cache.clear('user-a');

    expect(await cache.read('user-b'), other);
  });

  test('stored values that fail the goal rules count as no cache', () async {
    await db.customStatement(
      "INSERT INTO user_settings (user_id, goal_kcal, goal_protein_g, goal_fat_g, goal_carbs_g) VALUES ('user-a', 50, 1, 1, 1)",
    );

    expect(await cache.read('user-a'), isNull);
  });
}
