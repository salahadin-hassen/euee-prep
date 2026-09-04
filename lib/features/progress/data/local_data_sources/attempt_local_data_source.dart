import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/attempt_persistence_model.dart';

/// Local data source for the append-only `attempts` table (Decision 016).
///
/// Only layer allowed to execute Drift queries (Decision 026).
class AttemptLocalDataSource {
  AttemptLocalDataSource(this._database);

  final AppDatabase _database;

  Future<AttemptPersistenceModel> insert(
      AttemptPersistenceModel attempt) async {
    final id = await _database.into(_database.attempts).insert(
          AttemptsCompanion.insert(
            questionId: attempt.questionId,
            selectedChoiceIndex: attempt.selectedChoiceIndex,
            isCorrect: attempt.isCorrect ? 1 : 0,
            attemptedAt: attempt.attemptedAt,
            mode: Value(attempt.mode),
            durationSeconds: Value(attempt.durationSeconds),
            subjectId: Value(attempt.subjectId),
            chapterId: Value(attempt.chapterId),
            examId: Value(attempt.examId),
          ),
        );

    return AttemptPersistenceModel(
      id: id,
      questionId: attempt.questionId,
      selectedChoiceIndex: attempt.selectedChoiceIndex,
      isCorrect: attempt.isCorrect,
      attemptedAt: attempt.attemptedAt,
      mode: attempt.mode,
      durationSeconds: attempt.durationSeconds,
      subjectId: attempt.subjectId,
      chapterId: attempt.chapterId,
      examId: attempt.examId,
    );
  }

  Future<List<AttemptPersistenceModel>> getByQuestionId(int questionId) async {
    final rows = await (_database.select(_database.attempts)
          ..where((a) => a.questionId.equals(questionId))
          ..orderBy([(a) => OrderingTerm(expression: a.attemptedAt)]))
        .get();

    return rows.map(_mapRow).toList();
  }

  Future<List<AttemptPersistenceModel>> getAll() async {
    final rows = await (_database.select(_database.attempts)
          ..orderBy([(a) => OrderingTerm(expression: a.attemptedAt)]))
        .get();

    return rows.map(_mapRow).toList();
  }

  AttemptPersistenceModel _mapRow(Attempt row) {
    return AttemptPersistenceModel(
      id: row.id,
      questionId: row.questionId,
      selectedChoiceIndex: row.selectedChoiceIndex,
      isCorrect: row.isCorrect == 1,
      attemptedAt: row.attemptedAt,
      mode: row.mode,
      durationSeconds: row.durationSeconds,
      subjectId: row.subjectId,
      chapterId: row.chapterId,
      examId: row.examId,
    );
  }
}
