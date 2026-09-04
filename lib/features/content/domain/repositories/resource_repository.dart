import '../models/resource.dart';

abstract interface class ResourceRepository {
  Future<Resource> insert(Resource resource);

  Future<List<Resource>> getAll();

  Future<List<Resource>> getByTopicId(int topicId);
}
