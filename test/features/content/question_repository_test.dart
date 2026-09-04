import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/content/data/local_data_sources/question_local_data_source.dart';
import 'package:euee_prep/features/content/data/repositories/question_repository_impl.dart';
import 'package:euee_prep/features/content/domain/models/question.dart';

void main() {
  late db.AppDatabase database;
  late QuestionRepositoryImpl repository;

  test('migrates a v5 database to v8 with Exam mapping tables', () async {
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
      containsAll(<String>['questions', 'question_topics']),
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
      await database.into(database.chapters).insert(
            const db.ChaptersCompanion(
              id: drift.Value(1),
              subjectId: drift.Value(1),
              gradeId: drift.Value(1),
              sourcePackId: drift.Value('pack-1'),
              packLocalId: drift.Value('chapter-1'),
              title: drift.Value('Mechanics'),
              orderIndex: drift.Value(1),
            ),
          );
      await database.into(database.topics).insert(
            const db.TopicsCompanion(
              id: drift.Value(1),
              chapterId: drift.Value(1),
              sourcePackId: drift.Value('pack-1'),
              packLocalId: drift.Value('topic-1'),
              title: drift.Value('Motion'),
              orderIndex: drift.Value(1),
            ),
          );
      await database.into(database.topics).insert(
            const db.TopicsCompanion(
              id: drift.Value(2),
              chapterId: drift.Value(1),
              sourcePackId: drift.Value('pack-1'),
              packLocalId: drift.Value('topic-2'),
              title: drift.Value('Forces'),
              orderIndex: drift.Value(2),
            ),
          );
      repository = QuestionRepositoryImpl(QuestionLocalDataSource(database));
    });

    tearDown(() async {
      await database.close();
    });

    test('inserts and reads a question with multiple topics', () async {
      final inserted = await repository.insert(_question());
      final questions = await repository.getAll();

      expect(inserted, isA<Question>());
      expect(questions, hasLength(1));
      expect(questions.single.topicIds, [1, 2]);
      expect(questions.single.correctChoiceIndex, 2);
      expect(questions.single.explanation, 'Use Newtons laws.');
      expect(questions.single.examYearEc, 2015);
      expect(questions.single.imageReference, 'images/q1.png');
    });

    test('supports nullable question metadata', () async {
      await repository.insert(
        _question(
          id: 2,
          packLocalId: 'question-2',
          topicIds: const [],
          explanation: null,
          textbookReference: null,
          examYearEc: null,
          imageReference: null,
          graphReference: null,
          diagramReference: null,
          tableReference: null,
        ),
      );

      final question = (await repository.getAll()).single;
      expect(question.topicIds, isEmpty);
      expect(question.explanation, isNull);
      expect(question.examYearEc, isNull);
    });

    test('rejects invalid foreign keys and duplicate pack-local identity',
        () async {
      await expectLater(
        repository.insert(_question(sourcePackId: 'missing-pack')),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repository.insert(_question(topicIds: [99])),
        throwsA(isA<Exception>()),
      );

      await repository.insert(_question());
      await expectLater(
        repository.insert(_question(id: 2)),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects duplicate question-topic links', () async {
      await expectLater(
        repository.insert(_question(topicIds: [1, 1])),
        throwsA(isA<Exception>()),
      );
      expect(await repository.getAll(), isEmpty);
    });

    test('requires non-null question columns and preserves nullable fields',
        () async {
      final columns =
          await database.customSelect('PRAGMA table_info(questions)').get();
      final nullableColumns = columns
          .where((row) => row.read<int>('notnull') == 0)
          .map((row) => row.read<String>('name'))
          .toSet();

      expect(
        nullableColumns,
        {
          'explanation',
          'textbook_reference',
          'exam_year_ec',
          'image_reference',
          'graph_reference',
          'diagram_reference',
          'table_reference',
        },
      );
    });
  });
}

Question _question({
  int id = 1,
  String sourcePackId = 'pack-1',
  String packLocalId = 'question-1',
  List<int> topicIds = const [1, 2],
  String? explanation = 'Use Newtons laws.',
  String? textbookReference = 'Physics 11, chapter 2',
  int? examYearEc = 2015,
  String? imageReference = 'images/q1.png',
  String? graphReference = 'graphs/q1.png',
  String? diagramReference = 'diagrams/q1.png',
  String? tableReference = 'tables/q1.json',
}) {
  return Question(
    id: id,
    sourcePackId: sourcePackId,
    packLocalId: packLocalId,
    prompt: 'Which law explains this motion?',
    choicesJson: '["First", "Second", "Third", "None"]',
    correctChoiceIndex: 2,
    topicIds: topicIds,
    explanation: explanation,
    textbookReference: textbookReference,
    examYearEc: examYearEc,
    imageReference: imageReference,
    graphReference: graphReference,
    diagramReference: diagramReference,
    tableReference: tableReference,
  );
}
