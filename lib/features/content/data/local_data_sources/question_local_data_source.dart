import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/question_persistence_model.dart';

class QuestionLocalDataSource {
  QuestionLocalDataSource(this._database);

  final AppDatabase _database;

  Future<QuestionPersistenceModel> insert(
    QuestionPersistenceModel question,
  ) async {
    await _database.transaction(() async {
      await _database.into(_database.questions).insert(
            QuestionsCompanion.insert(
              id: Value(question.id),
              sourcePackId: question.sourcePackId,
              packLocalId: question.packLocalId,
              prompt: question.prompt,
              choicesJson: question.choicesJson,
              correctChoiceIndex: question.correctChoiceIndex,
              explanation: Value(question.explanation),
              textbookReference: Value(question.textbookReference),
              examYearEc: Value(question.examYearEc),
              imageReference: Value(question.imageReference),
              graphReference: Value(question.graphReference),
              diagramReference: Value(question.diagramReference),
              tableReference: Value(question.tableReference),
            ),
          );

      if (question.topicIds.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.questionTopics,
            question.topicIds
                .map(
                  (topicId) => QuestionTopicsCompanion(
                    questionId: Value(question.id),
                    topicId: Value(topicId),
                  ),
                )
                .toList(),
          );
        });
      }
    });
    return question;
  }

  Future<List<QuestionPersistenceModel>> getAll() async {
    final rows = await _database.select(_database.questions).get();
    final links = await _database.select(_database.questionTopics).get();
    final topicIdsByQuestion = <int, List<int>>{};
    for (final link in links) {
      topicIdsByQuestion
          .putIfAbsent(link.questionId, () => <int>[])
          .add(link.topicId);
    }

    return rows
        .map(
          (row) => _mapRow(
            row,
            topicIdsByQuestion[row.id] ?? const <int>[],
          ),
        )
        .toList();
  }

  QuestionPersistenceModel _mapRow(Question row, List<int> topicIds) {
    return QuestionPersistenceModel(
      id: row.id,
      sourcePackId: row.sourcePackId,
      packLocalId: row.packLocalId,
      prompt: row.prompt,
      choicesJson: row.choicesJson,
      correctChoiceIndex: row.correctChoiceIndex,
      topicIds: List.unmodifiable(topicIds),
      explanation: row.explanation,
      textbookReference: row.textbookReference,
      examYearEc: row.examYearEc,
      imageReference: row.imageReference,
      graphReference: row.graphReference,
      diagramReference: row.diagramReference,
      tableReference: row.tableReference,
    );
  }
}
