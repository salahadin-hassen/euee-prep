import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/subject_persistence_model.dart';

class SubjectLocalDataSource {
  SubjectLocalDataSource(this._database);

  final AppDatabase _database;

  Future<SubjectPersistenceModel> insert(
      SubjectPersistenceModel subject) async {
    await _database.into(_database.subjects).insert(
          SubjectsCompanion.insert(
            id: Value(subject.id),
            streamId: subject.streamId,
            slug: subject.slug,
            title: subject.title,
          ),
        );
    return subject;
  }

  Future<List<SubjectPersistenceModel>> getAll() async {
    final rows = await _database.select(_database.subjects).get();
    return rows
        .map(
          (row) => SubjectPersistenceModel(
            id: row.id,
            streamId: row.streamId,
            slug: row.slug,
            title: row.title,
          ),
        )
        .toList();
  }
}
