import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/chapter_persistence_model.dart';

class ChapterLocalDataSource {
  ChapterLocalDataSource(this._database);

  final AppDatabase _database;

  Future<ChapterPersistenceModel> insert(
      ChapterPersistenceModel chapter) async {
    await _database.into(_database.chapters).insert(
          ChaptersCompanion.insert(
            id: Value(chapter.id),
            subjectId: chapter.subjectId,
            gradeId: chapter.gradeId,
            sourcePackId: chapter.sourcePackId,
            packLocalId: chapter.packLocalId,
            title: chapter.title,
            orderIndex: chapter.orderIndex,
          ),
        );
    return chapter;
  }

  Future<List<ChapterPersistenceModel>> getAll() async {
    final rows = await _database.select(_database.chapters).get();
    return rows.map(_mapRow).toList();
  }

  ChapterPersistenceModel _mapRow(Chapter row) {
    return ChapterPersistenceModel(
      id: row.id,
      subjectId: row.subjectId,
      gradeId: row.gradeId,
      sourcePackId: row.sourcePackId,
      packLocalId: row.packLocalId,
      title: row.title,
      orderIndex: row.orderIndex,
    );
  }
}
