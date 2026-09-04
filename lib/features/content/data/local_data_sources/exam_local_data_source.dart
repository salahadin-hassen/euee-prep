import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/exam_persistence_model.dart';

class ExamLocalDataSource {
  ExamLocalDataSource(this._database);

  final AppDatabase _database;

  Future<ExamPersistenceModel> insert(ExamPersistenceModel exam) async {
    await _database.transaction(() async {
      await _database.into(_database.exams).insert(
            ExamsCompanion.insert(
              id: Value(exam.id),
              sourcePackId: exam.sourcePackId,
              packLocalId: exam.packLocalId,
              subjectId: exam.subjectId,
              examYearEc: exam.examYearEc,
              title: Value(exam.title),
              durationSeconds: Value(exam.durationSeconds),
            ),
          );

      if (exam.questionIds.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.examQuestions,
            exam.questionIds
                .asMap()
                .entries
                .map(
                  (entry) => ExamQuestionsCompanion(
                    examId: Value(exam.id),
                    questionId: Value(entry.value),
                    orderIndex: Value(entry.key),
                  ),
                )
                .toList(),
          );
        });
      }
    });
    return exam;
  }

  Future<List<ExamPersistenceModel>> getAll() async {
    final exams = await _database.select(_database.exams).get();
    final links = await (_database.select(_database.examQuestions)
          ..orderBy([
            (link) => OrderingTerm(expression: link.orderIndex),
          ]))
        .get();
    final questionIdsByExam = <int, List<int>>{};
    for (final link in links) {
      questionIdsByExam
          .putIfAbsent(link.examId, () => <int>[])
          .add(link.questionId);
    }

    return exams
        .map(
          (exam) => ExamPersistenceModel(
            id: exam.id,
            sourcePackId: exam.sourcePackId,
            packLocalId: exam.packLocalId,
            subjectId: exam.subjectId,
            examYearEc: exam.examYearEc,
            questionIds: questionIdsByExam[exam.id] ?? const <int>[],
            title: exam.title,
            durationSeconds: exam.durationSeconds,
          ),
        )
        .toList();
  }
}
