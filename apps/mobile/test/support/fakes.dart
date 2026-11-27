import 'dart:async';

import 'package:lean_tracker/auth/auth.dart';
import 'package:lean_tracker/diary/application/entry_repository.dart';
import 'package:lean_tracker/diary/application/product_source.dart';
import 'package:lean_tracker/diary/domain/diary_entry.dart';
import 'package:lean_tracker/diary/domain/product_snapshot.dart';
import 'package:lean_tracker/kernel/clock.dart';
import 'package:lean_tracker/kernel/local_date.dart';
import 'package:lean_tracker/kernel/uuid.dart';
import 'package:lean_tracker/settings/settings.dart';

/// Records calls and answers with [result]. [emit] plays the part of the SDK's status stream.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    AuthStatus initial = AuthStatus.signedOut,
    this.result = const AuthOk(),
    this.currentUserId = 'user-1',
  }) : _current = initial;

  AuthResult result;

  /// Set it to play the signed-in user's id.
  @override
  String? currentUserId;
  final calls = <String>[];
  final _controller = StreamController<AuthStatus>.broadcast();
  AuthStatus _current;

  void emit(AuthStatus status) {
    _current = status;
    _controller.add(status);
  }

  @override
  Stream<AuthStatus> get status => _controller.stream;

  @override
  AuthStatus get current => _current;

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<AuthResult> signUp(Email email, Password password) async {
    calls.add('signUp');
    return result;
  }

  @override
  Future<AuthResult> signIn(Email email, Password password) async {
    calls.add('signIn');
    return result;
  }

  @override
  Future<AuthResult> signInWithProvider(SocialProvider provider) async {
    calls.add('signInWithProvider:${provider.name}');
    return result;
  }

  @override
  Future<AuthResult> requestPasswordReset(Email email) async {
    calls.add('requestPasswordReset');
    return result;
  }

  @override
  Future<AuthResult> setNewPassword(Password password) async {
    calls.add('setNewPassword');
    return result;
  }

  @override
  Future<AuthResult> signOut() async {
    calls.add('signOut');
    return result;
  }
}

class FakeGoalsRepository implements GoalsRepository {
  FakeGoalsRepository({this.loadResult = const GoalsMissing()});

  GoalsLoad loadResult;

  /// The answer of [save]; null saves and echoes the goals.
  GoalsSave? saveResult;
  final saved = <Goals>[];

  @override
  Future<GoalsLoad> load() async => loadResult;

  @override
  Future<GoalsSave> save(Goals goals) async {
    saved.add(goals);
    return saveResult ?? GoalsSaved(goals);
  }
}

/// In-memory [GoalsCache], one slot per user.
class FakeGoalsCache implements GoalsCache {
  final goals = <String, Goals>{};

  @override
  Future<Goals?> read(String userId) async => goals[userId];

  @override
  Future<void> write(String userId, Goals value) async => goals[userId] = value;

  @override
  Future<void> clear(String userId) async => goals.remove(userId);
}

/// In-memory [EntryRepository]. Like the real one it hides soft-deleted entries and orders a day by
/// `updatedAt`, then `id`. Set [failSaves] to make every save fail.
class FakeEntryRepository implements EntryRepository {
  final _rows = <String, DiaryEntry>{};
  final _changes = StreamController<void>.broadcast();
  bool failSaves = false;
  final saves = <DiaryEntry>[];

  /// Every stored entry, soft-deleted ones included.
  List<DiaryEntry> get stored => _rows.values.toList();

  List<DiaryEntry> _day(LocalDate date) {
    final live = _rows.values
        .where((e) => e.entryDate == date && e.deletedAt == null)
        .toList();
    live.sort((a, b) {
      final byTime = a.updatedAt.compareTo(b.updatedAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return live;
  }

  @override
  Stream<List<DiaryEntry>> watchDay(LocalDate date) async* {
    yield _day(date);
    await for (final _ in _changes.stream) {
      yield _day(date);
    }
  }

  @override
  Future<DiaryEntry?> findById(String id) async {
    final row = _rows[id];
    return row == null || row.deletedAt != null ? null : row;
  }

  @override
  Future<SaveResult> save(DiaryEntry entry) async {
    if (failSaves) return const SaveFailed();
    saves.add(entry);
    _rows[entry.id] = entry;
    _changes.add(null);
    return const Saved();
  }
}

/// A clock that stands still until a test moves it.
class FakeClock implements Clock {
  FakeClock([DateTime? start])
    : current = start ?? DateTime.utc(2026, 11, 25, 8);

  DateTime current;

  @override
  DateTime now() => current;
}

/// Hands out `id-1`, `id-2`, ...
class FakeUuid implements Uuid {
  var _n = 0;

  @override
  String v4() => 'id-${++_n}';
}

class FakeProductSource implements ProductSource {
  const FakeProductSource([this._products = const []]);

  final List<ProductSnapshot> _products;

  @override
  List<ProductSnapshot> products() => _products;
}
