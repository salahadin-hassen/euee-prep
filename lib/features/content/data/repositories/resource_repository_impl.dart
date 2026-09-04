import '../../domain/models/resource.dart';
import '../../domain/repositories/resource_repository.dart';
import '../local_data_sources/resource_local_data_source.dart';
import '../models/resource_persistence_model.dart';

class ResourceRepositoryImpl implements ResourceRepository {
  ResourceRepositoryImpl(this._localDataSource);

  final ResourceLocalDataSource _localDataSource;

  @override
  Future<Resource> insert(Resource resource) async {
    final model = await _localDataSource.insert(_toPersistence(resource));
    return _toDomain(model);
  }

  @override
  Future<List<Resource>> getByTopicId(int topicId) async {
    final models = await _localDataSource.getByTopicId(topicId);
    return models.map(_toDomain).toList();
  }

  ResourcePersistenceModel _toPersistence(Resource resource) {
    return ResourcePersistenceModel(
      id: resource.id,
      topicId: resource.topicId,
      sourcePackId: resource.sourcePackId,
      packLocalId: resource.packLocalId,
      type: resource.type.name,
      title: resource.title,
      content: resource.content,
      orderIndex: resource.orderIndex,
    );
  }

  Resource _toDomain(ResourcePersistenceModel model) {
    return Resource(
      id: model.id,
      topicId: model.topicId,
      sourcePackId: model.sourcePackId,
      packLocalId: model.packLocalId,
      type: ResourceType.values.firstWhere((e) => e.name == model.type),
      title: model.title,
      content: model.content,
      orderIndex: model.orderIndex,
    );
  }
}
