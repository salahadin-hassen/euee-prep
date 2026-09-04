import '../models/topic.dart';

abstract interface class TopicRepository {
  Future<Topic> insert(Topic topic);

  Future<List<Topic>> getAll();
}
