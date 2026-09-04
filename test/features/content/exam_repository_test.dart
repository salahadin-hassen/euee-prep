import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/content/data/local_data_sources/exam_local_data_source.dart';
import 'package:euee_prep/features/content/data/repositories/exam_repository_impl.dart';
import 'package:euee_prep/features/content/domain/models/exam.dart';

void main() {
  late db.AppDatabase database;
  late ExamRepositoryImpl repository;

  test('migrates a v5 database to v8 with Exam tables', () async {
    final oldDatabase = db.AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDatabase) {
          rawDatabase.execute('PRAGMA user_version = 5');
        },
      ),
    );

    await oldDatabase.customSelect('SELECT 1').get();

    expect(oldDatabase.schemaVersion, 8);
    expect(
      oldDatabase.allTables.map((table) => table.actualTableName),
      containsAll(<String>['exams', 'exam_questions']),
    );
    await oldDatabase.close();
  });

  group('repository', () {
    setUp(() async {
      database = db.AppDatabase.forTesting(NativeDatabase.memory());
      await database.into(database.grades).insert(
            const db.GradesCompanion(
              id: drift.Value(1),
              level: drift.Value(11),
            ),
          );
      await database.into(database.streams).insert(
            const db.StreamsCompanion(
              id: drift.Value(1),
              slug: drift.Value('natural_science'),
            ),
          );
      await database.into(database.subjects).insert(
            const db.SubjectsCompanion(
              id: drift.Value(1),
              streamId: drift.Value(1),
              slug: drift.Value('physics'),
              title: drift.Value('Physics'),
            ),
          );
      await database.into(database.contentPacks).insert(
            db.ContentPacksCompanion.insert(
              id: 'pack-1',
              packKey: 'natural_science-physics',
              subjectId: 1,
              packVersion: '1.0.0',
              schemaVersion: '2',
              generatedAt: '2025-12-01T00:00:00Z',
              checksum: 'sha256:one',
              minimumAppVersion: '0.1.0',
              importedAt: '2026-01-01T00:00:00Z',
            ),
          );
      await database.into(database.questions).insert(
            const db.QuestionsCompanion(
              id: drift.Value(1),
              sourcePackId: drift.Value('pack-1'),
              packLocalId: drift.Value('question-1'),
              prompt: drift.Value('Which law explains motion?'),
              choicesJson: drift.Value('["First", "Second", "Third"]'),
              correctChoiceIndex: drift.Value(2),
            ),
          );
      await database.into(database.questions).insert(
            const db.QuestionsCompanion(
              id: drift.Value(2),
              sourcePackId: drift.Value('pack-1'),
              packLocalId: drift.Value('question-2'),
              prompt: drift.Value('Which quantity is conserved?'),
              choicesJson: drift.Value('["Mass", "Time"]'),
              correctChoiceIndex: drift.Value(0),
            ),
          );
      repository = ExamRepositoryImpl(ExamLocalDataSource(database));
    });

    tearDown(() async {
      await database.close();
    });

    test('stores explicit question ordering', () async {
      await repository.insert(_exam());

      final exams = await repository.getAll();

      expect(exams.single.questionIds, [2, 1]);
      expect(exams.single.examYearEc, 2015);
      expect(exams.single.durationSeconds, 12600);
    });

    test('rejects invalid foreign keys and duplicate identities', () async {
      await expectLater(
        repository.insert(_exam(sourcePackId: 'missing-pack')),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repository.insert(_exam(questionIds: [99])),
        throwsA(isA<Exception>()),
      );

      await repository.insert(_exam());
      await expectLater(
        repository.insert(_exam(id: 2, packLocalId: 'exam-2')),
        throwsA(isA<Exception>()),
      );
    });

    test('rolls back an exam when ordered membership is invalid', () async {
      await expectLater(
        repository.insert(_exam(questionIds: [1, 1])),
        throwsA(isA<Exception>()),
      );

      expect(await repository.getAll(), isEmpty);
    });
  });
}

Exam _exam({
  int id = 1,
  String sourcePackId = 'pack-1',
  String packLocalId = 'exam-1',
  List<int> questionIds = const [2, 1],
}) {
  return Exam(
    id: id,
    sourcePackId: sourcePackId,
    packLocalId: packLocalId,
    subjectId: 1,
    examYearEc: 2015,
    questionIds: questionIds,
    title: 'EUEE Physics 2015',
    durationSeconds: 12600,
  );
}
