import '../../kernel/local_date.dart';
import '../domain/diary_entry.dart';

/// Where diary entries live. Declared by the use cases, implemented in `infrastructure`. One instance
/// serves one signed-in user, so no method takes a user id and none can reach another user's rows (BR-001).
abstract interface class EntryRepository {
  /// The live entries of [date], oldest first. Soft-deleted entries are not included.
  Stream<List<DiaryEntry>> watchDay(LocalDate date);

  /// The live entry [id], or null when there is none (unknown, deleted or another user's).
  Future<DiaryEntry?> findById(String id);

  /// Inserts or replaces the entry (a soft delete is a save with `deletedAt` set).
  Future<SaveResult> save(DiaryEntry entry);
}

/// Result of [EntryRepository.save]. Failures are values, never exceptions (AD5).
sealed class SaveResult {
  const SaveResult();
}

final class Saved extends SaveResult {
  const Saved();
}

/// The entry could not be written; nothing changed.
final class SaveFailed extends SaveResult {
  const SaveFailed();
}
