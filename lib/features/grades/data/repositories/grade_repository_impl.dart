import '../../domain/models/grade.dart';
import '../../domain/repositories/grade_repository.dart';
import '../local_data_sources/grade_local_data_source.dart';
import '../models/grade_persistence_model.dart';

class GradeRepositoryImpl implements GradeRepository {
  GradeRepositoryImpl(this._localDataSource);

  final GradeLocalDataSource _localDataSource;

  @override
  Future<Grade> insert(Grade grade) async {
    final model = await _localDataSource.insert(
      GradePersistenceModel(id: grade.id, level: grade.level),
    );
    return Grade(id: model.id, level: model.level);
  }

  @override
  Future<List<Grade>> getAll() async {
    final models = await _localDataSource.getAll();
    return models
        .map((model) => Grade(id: model.id, level: model.level))
        .toList();
  }
}
