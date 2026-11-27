import '../../kernel/clock.dart';
import 'entry_repository.dart';

/// Result of [DeleteEntry].
sealed class DeleteEntryResult {
  const DeleteEntryResult();
}

final class EntryDeleted extends DeleteEntryResult {
  const EntryDeleted();
}

/// No live entry has this id.
final class DeleteEntryNotFound extends DeleteEntryResult {
  const DeleteEntryNotFound();
}

final class DeleteNotSaved extends DeleteEntryResult {
  const DeleteNotSaved();
}

/// Soft-deletes an entry: `deletedAt` and `updatedAt` are set, the row stays for sync (PRD §13).
class DeleteEntry {
  const DeleteEntry(this._repository, this._clock);

  final EntryRepository _repository;
  final Clock _clock;

  Future<DeleteEntryResult> call(String id) async {
    final existing = await _repository.findById(id);
    if (existing == null) return const DeleteEntryNotFound();
    final result = await _repository.save(
      existing.delete(_clock.now().toUtc()),
    );
    return switch (result) {
      Saved() => const EntryDeleted(),
      SaveFailed() => const DeleteNotSaved(),
    };
  }
}
