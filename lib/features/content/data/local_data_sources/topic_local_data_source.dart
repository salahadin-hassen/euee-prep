import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/topic_persistence_model.dart';

class TopicLocalDataSource {
  TopicLocalDataSource(this._database);

  final AppDatabase _database;

  Future<TopicPersistenceModel> insert(TopicPersistenceModel topic) async {
    await _database.into(_database.topics).insert(
          TopicsCompanion.insert(
            id: Value(topic.id),
            chapterId: topic.chapterId,
            sourcePackId: topic.sourcePackId,
            packLocalId: topic.packLocalId,
            title: topic.title,
            orderIndex: topic.orderIndex,
          ),
        );
    return topic;
  }

  Future<List<TopicPersistenceModel>> getAll() async {
    final rows = await _database.select(_database.topics).get();
    return rows.map(_mapRow).toList();
  }

  TopicPersistenceModel _mapRow(Topic row) {
    return TopicPersistenceModel(
      id: row.id,
      chapterId: row.chapterId,
      sourcePackId: row.sourcePackId,
      packLocalId: row.packLocalId,
      title: row.title,
      orderIndex: row.orderIndex,
    );
  }
}
