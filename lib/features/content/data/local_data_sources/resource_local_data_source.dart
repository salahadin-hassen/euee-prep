import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/resource_persistence_model.dart';

class ResourceLocalDataSource {
  ResourceLocalDataSource(this._database);

  final AppDatabase _database;

  Future<ResourcePersistenceModel> insert(
      ResourcePersistenceModel resource) async {
    await _database.into(_database.resources).insert(
          ResourcesCompanion.insert(
            id: Value(resource.id),
            topicId: resource.topicId,
            sourcePackId: resource.sourcePackId,
            packLocalId: resource.packLocalId,
            type: resource.type,
            title: Value(resource.title),
            content: resource.content,
            orderIndex: resource.orderIndex,
          ),
        );
    return resource;
  }

  Future<List<ResourcePersistenceModel>> getAll() async {
    final rows = await (_database.select(_database.resources)
          ..orderBy([(r) => OrderingTerm(expression: r.id)]))
        .get();

    return rows.map(_mapRow).toList();
  }

  Future<List<ResourcePersistenceModel>> getByTopicId(int topicId) async {
    final rows = await (_database.select(_database.resources)
          ..where((r) => r.topicId.equals(topicId))
          ..orderBy([(r) => OrderingTerm(expression: r.orderIndex)]))
        .get();

    return rows.map(_mapRow).toList();
  }

  ResourcePersistenceModel _mapRow(Resource row) {
    return ResourcePersistenceModel(
      id: row.id,
      topicId: row.topicId,
      sourcePackId: row.sourcePackId,
      packLocalId: row.packLocalId,
      type: row.type,
      title: row.title,
      content: row.content,
      orderIndex: row.orderIndex,
    );
  }
}
