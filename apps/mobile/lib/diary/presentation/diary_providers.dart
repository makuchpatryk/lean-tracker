import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kernel/clock.dart';
import '../../kernel/local_date.dart';
import '../../kernel/uuid.dart';
import '../application/add_entry.dart';
import '../application/daily_goals.dart';
import '../application/delete_entry.dart';
import '../application/edit_entry.dart';
import '../application/entry_repository.dart';
import '../application/product_source.dart';
import '../application/watch_day.dart';
import '../domain/diary_entry.dart';

/// Override points (ARCHITECTURE AD9): `app/` plugs in the real adapters, tests plug in fakes. A
/// provider that is not overridden fails loudly instead of running with a hidden default.
final entryRepositoryProvider = Provider<EntryRepository>(
  (ref) => throw UnimplementedError(
    'Override entryRepositoryProvider in the ProviderScope.',
  ),
);

final productSourceProvider = Provider<ProductSource>(
  (ref) => throw UnimplementedError(
    'Override productSourceProvider in the ProviderScope.',
  ),
);

/// The signed-in user's goals, or null while they are not known.
final dailyGoalsProvider = Provider<DailyGoals?>(
  (ref) => throw UnimplementedError(
    'Override dailyGoalsProvider in the ProviderScope.',
  ),
);

final clockProvider = Provider<Clock>(
  (ref) =>
      throw UnimplementedError('Override clockProvider in the ProviderScope.'),
);

final uuidProvider = Provider<Uuid>(
  (ref) =>
      throw UnimplementedError('Override uuidProvider in the ProviderScope.'),
);

final addEntryProvider = Provider(
  (ref) => AddEntry(
    ref.watch(entryRepositoryProvider),
    ref.watch(clockProvider),
    ref.watch(uuidProvider),
  ),
);

final editEntryProvider = Provider(
  (ref) =>
      EditEntry(ref.watch(entryRepositoryProvider), ref.watch(clockProvider)),
);

final deleteEntryProvider = Provider(
  (ref) =>
      DeleteEntry(ref.watch(entryRepositoryProvider), ref.watch(clockProvider)),
);

final watchDayProvider = Provider(
  (ref) => WatchDay(ref.watch(entryRepositoryProvider)),
);

/// The day the Diary shows. Starts at today's local date from the injected clock (BR-004).
final selectedDateProvider = NotifierProvider<SelectedDate, LocalDate>(
  SelectedDate.new,
);

class SelectedDate extends Notifier<LocalDate> {
  @override
  LocalDate build() => LocalDate.of(ref.read(clockProvider).now());

  void next() => state = state.addDays(1);

  void previous() => state = state.addDays(-1);

  void set(LocalDate date) => state = date;
}

/// One day of the Diary, live. Without goals there is nothing to show against, so it stays loading;
/// the route guard keeps a user without goals out of the Diary anyway (BP-006).
final dayProvider = StreamProvider.family<DiaryDay, LocalDate>((ref, date) {
  final goals = ref.watch(dailyGoalsProvider);
  if (goals == null) return const Stream.empty();
  return ref.watch(watchDayProvider)(date, goals);
});

/// A live entry by id, for the edit form. Auto-disposed, so reopening the form reads the stored entry.
final entryProvider = FutureProvider.autoDispose.family<DiaryEntry?, String>(
  (ref, id) => ref.watch(entryRepositoryProvider).findById(id),
);
