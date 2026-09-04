import '../../domain/models/topic.dart';
import '../../domain/repositories/topic_repository.dart';
import '../local_data_sources/topic_local_data_source.dart';
import '../models/topic_persistence_model.dart';

class TopicRepositoryImpl implements TopicRepository {
  TopicRepositoryImpl(this._localDataSource);

  final TopicLocalDataSource _localDataSource;

  @override
  Future<Topic> insert(Topic topic) async {
    final model = await _localDataSource.insert(_toPersistence(topic));
    return _toDomain(model);
  }

  @override
  Future<List<Topic>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map(_toDomain).toList();
  }

  TopicPersistenceModel _toPersistence(Topic topic) {
    return TopicPersistenceModel(
      id: topic.id,
      chapterId: topic.chapterId,
      sourcePackId: topic.sourcePackId,
      packLocalId: topic.packLocalId,
      title: topic.title,
      orderIndex: topic.orderIndex,
    );
  }

  Topic _toDomain(TopicPersistenceModel topic) {
    return Topic(
      id: topic.id,
      chapterId: topic.chapterId,
      sourcePackId: topic.sourcePackId,
      packLocalId: topic.packLocalId,
      title: topic.title,
      orderIndex: topic.orderIndex,
    );
  }
}
