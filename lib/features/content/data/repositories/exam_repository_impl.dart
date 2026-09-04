import '../../domain/models/exam.dart';
import '../../domain/repositories/exam_repository.dart';
import '../local_data_sources/exam_local_data_source.dart';
import '../models/exam_persistence_model.dart';

class ExamRepositoryImpl implements ExamRepository {
  ExamRepositoryImpl(this._localDataSource);

  final ExamLocalDataSource _localDataSource;

  @override
  Future<Exam> insert(Exam exam) async {
    final model = await _localDataSource.insert(_toPersistence(exam));
    return _toDomain(model);
  }

  @override
  Future<List<Exam>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map(_toDomain).toList();
  }

  ExamPersistenceModel _toPersistence(Exam exam) {
    return ExamPersistenceModel(
      id: exam.id,
      sourcePackId: exam.sourcePackId,
      packLocalId: exam.packLocalId,
      subjectId: exam.subjectId,
      examYearEc: exam.examYearEc,
      questionIds: exam.questionIds,
      title: exam.title,
      durationSeconds: exam.durationSeconds,
    );
  }

  Exam _toDomain(ExamPersistenceModel exam) {
    return Exam(
      id: exam.id,
      sourcePackId: exam.sourcePackId,
      packLocalId: exam.packLocalId,
      subjectId: exam.subjectId,
      examYearEc: exam.examYearEc,
      questionIds: exam.questionIds,
      title: exam.title,
      durationSeconds: exam.durationSeconds,
    );
  }
}
