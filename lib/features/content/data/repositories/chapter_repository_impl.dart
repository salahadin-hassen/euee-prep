import '../../domain/models/chapter.dart';
import '../../domain/repositories/chapter_repository.dart';
import '../local_data_sources/chapter_local_data_source.dart';
import '../models/chapter_persistence_model.dart';

class ChapterRepositoryImpl implements ChapterRepository {
  ChapterRepositoryImpl(this._localDataSource);

  final ChapterLocalDataSource _localDataSource;

  @override
  Future<Chapter> insert(Chapter chapter) async {
    final model = await _localDataSource.insert(_toPersistence(chapter));
    return _toDomain(model);
  }

  @override
  Future<List<Chapter>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map(_toDomain).toList();
  }

  ChapterPersistenceModel _toPersistence(Chapter chapter) {
    return ChapterPersistenceModel(
      id: chapter.id,
      subjectId: chapter.subjectId,
      gradeId: chapter.gradeId,
      sourcePackId: chapter.sourcePackId,
      packLocalId: chapter.packLocalId,
      title: chapter.title,
      orderIndex: chapter.orderIndex,
    );
  }

  Chapter _toDomain(ChapterPersistenceModel chapter) {
    return Chapter(
      id: chapter.id,
      subjectId: chapter.subjectId,
      gradeId: chapter.gradeId,
      sourcePackId: chapter.sourcePackId,
      packLocalId: chapter.packLocalId,
      title: chapter.title,
      orderIndex: chapter.orderIndex,
    );
  }
}
