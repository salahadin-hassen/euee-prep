import '../../domain/models/attempt.dart';
import '../../domain/repositories/attempt_repository.dart';
import '../local_data_sources/attempt_local_data_source.dart';
import '../models/attempt_persistence_model.dart';

/// Append-only repository for Attempt records (Decision 016).
///
/// Exposes exactly one write method: `insert`. No `update`, no `delete`.
class AttemptRepositoryImpl implements AttemptRepository {
  AttemptRepositoryImpl(this._localDataSource);

  final AttemptLocalDataSource _localDataSource;

  @override
  Future<Attempt> insert(Attempt attempt) async {
    final model = await _localDataSource.insert(_toPersistence(attempt));
    return _toDomain(model);
  }

  @override
  Future<List<Attempt>> getByQuestionId(int questionId) async {
    final models = await _localDataSource.getByQuestionId(questionId);
    return models.map(_toDomain).toList();
  }

  @override
  Future<List<Attempt>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map(_toDomain).toList();
  }

  AttemptPersistenceModel _toPersistence(Attempt attempt) {
    return AttemptPersistenceModel(
      id: attempt.id,
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

  Attempt _toDomain(AttemptPersistenceModel model) {
    return Attempt(
      id: model.id,
      questionId: model.questionId,
      selectedChoiceIndex: model.selectedChoiceIndex,
      isCorrect: model.isCorrect,
      attemptedAt: model.attemptedAt,
      mode: model.mode,
      durationSeconds: model.durationSeconds,
      subjectId: model.subjectId,
      chapterId: model.chapterId,
      examId: model.examId,
    );
  }
}
