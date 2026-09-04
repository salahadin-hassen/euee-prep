import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/grade_persistence_model.dart';

class GradeLocalDataSource {
  GradeLocalDataSource(this._database);

  final AppDatabase _database;

  Future<GradePersistenceModel> insert(GradePersistenceModel grade) async {
    await _database.into(_database.grades).insert(
          GradesCompanion.insert(id: Value(grade.id), level: grade.level),
        );
    return grade;
  }

  Future<List<GradePersistenceModel>> getAll() async {
    final rows = await _database.select(_database.grades).get();
    return rows
        .map((row) => GradePersistenceModel(id: row.id, level: row.level))
        .toList();
  }
}
