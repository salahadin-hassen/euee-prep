import '../../domain/models/subject.dart';
import '../../domain/repositories/subject_repository.dart';
import '../local_data_sources/subject_local_data_source.dart';
import '../models/subject_persistence_model.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  SubjectRepositoryImpl(this._localDataSource);

  final SubjectLocalDataSource _localDataSource;

  @override
  Future<Subject> insert(Subject subject) async {
    final model = await _localDataSource.insert(
      SubjectPersistenceModel(
        id: subject.id,
        streamId: subject.streamId,
        slug: subject.slug,
        title: subject.title,
      ),
    );
    return Subject(
      id: model.id,
      streamId: model.streamId,
      slug: model.slug,
      title: model.title,
    );
  }

  @override
  Future<List<Subject>> getAll() async {
    final models = await _localDataSource.getAll();
    return models
        .map(
          (model) => Subject(
            id: model.id,
            streamId: model.streamId,
            slug: model.slug,
            title: model.title,
          ),
        )
        .toList();
  }

  @override
  Future<List<Subject>> getByStreamId(int streamId) async {
    final models = await _localDataSource.getByStreamId(streamId);
    return models
        .map(
          (model) => Subject(
            id: model.id,
            streamId: model.streamId,
            slug: model.slug,
            title: model.title,
          ),
        )
        .toList();
  }

  @override
  Future<Subject?> getByStreamAndSlug(int streamId, String slug) async {
    final model = await _localDataSource.getByStreamAndSlug(streamId, slug);
    return model == null
        ? null
        : Subject(
            id: model.id,
            streamId: model.streamId,
            slug: model.slug,
            title: model.title,
          );
  }
}
