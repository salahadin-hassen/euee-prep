import '../models/attempt.dart';

/// Repository for Attempt records.
///
/// **Append-only (Decision 016):** exposes exactly one write method (`insert`).
/// No `update`, no `delete`, no `replace`, no `overwrite` — ever. Attempt
/// history is the permanent source of truth for all downstream analytics.
abstract interface class AttemptRepository {
  Future<Attempt> insert(Attempt attempt);

  Future<List<Attempt>> getByQuestionId(int questionId);

  Future<List<Attempt>> getAll();
}
