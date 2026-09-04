import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/stream_persistence_model.dart';

class StreamLocalDataSource {
  StreamLocalDataSource(this._database);

  final AppDatabase _database;

  Future<StreamPersistenceModel> insert(StreamPersistenceModel stream) async {
    await _database.into(_database.streams).insert(
          StreamsCompanion.insert(id: Value(stream.id), slug: stream.slug),
        );
    return stream;
  }

  Future<List<StreamPersistenceModel>> getAll() async {
    final rows = await _database.select(_database.streams).get();
    return rows
        .map((row) => StreamPersistenceModel(id: row.id, slug: row.slug))
        .toList();
  }
}
