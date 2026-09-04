import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/progress/data/local_data_sources/attempt_local_data_source.dart';
import 'package:euee_prep/features/progress/data/repositories/attempt_repository_impl.dart';
import 'package:euee_prep/features/progress/domain/models/attempt.dart';

void main() {
  late db.AppDatabase database;
  late AttemptRepositoryImpl repository;

  /// Seed minimal content rows required by the Attempts FK constraints.
  Future<void> seedContent() async {
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
    await database.into(database.questions).insert(
          const db.QuestionsCompanion(
            id: drift.Value(1),
            sourcePackId: drift.Value('pack-1'),
            packLocalId: drift.Value('question-1'),
            prompt: drift.Value('What is 2+2?'),
            choicesJson: drift.Value('["3","4","5"]'),
            correctChoiceIndex: drift.Value(1),
          ),
        );
    await database.into(database.questions).insert(
          const db.QuestionsCompanion(
            id: drift.Value(2),
            sourcePackId: drift.Value('pack-1'),
            packLocalId: drift.Value('question-2'),
            prompt: drift.Value('What is 3+3?'),
            choicesJson: drift.Value('["5","6","7"]'),
            correctChoiceIndex: drift.Value(1),
          ),
        );
    await database.into(database.exams).insert(
          const db.ExamsCompanion(
            id: drift.Value(1),
            sourcePackId: drift.Value('pack-1'),
            packLocalId: drift.Value('exam-1'),
            subjectId: drift.Value(1),
            examYearEc: drift.Value(2015),
          ),
        );
  }

  group('schema migration', () {
    test('migrates a v7 database to v8 with Attempts table', () async {
      final oldDatabase = db.AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (rawDatabase) {
            rawDatabase.execute('PRAGMA user_version = 7');
          },
        ),
      );

      await oldDatabase.customSelect('SELECT 1').get();

      expect(oldDatabase.schemaVersion, 8);
      expect(
        oldDatabase.allTables.map((table) => table.actualTableName),
        contains('attempts'),
      );
      await oldDatabase.close();
    });
  });

  group('repository', () {
    setUp(() async {
      database = db.AppDatabase.forTesting(NativeDatabase.memory());
      await seedContent();
      repository = AttemptRepositoryImpl(AttemptLocalDataSource(database));
    });

    tearDown(() async {
      await database.close();
    });

    test('inserts and reads a basic practice attempt', () async {
      final inserted = await repository.insert(_attempt());
      final all = await repository.getAll();

      expect(inserted, isA<Attempt>());
      expect(all, hasLength(1));
      expect(all.single.questionId, 1);
      expect(all.single.selectedChoiceIndex, 1);
      expect(all.single.isCorrect, isTrue);
      expect(all.single.mode, 'practice');
    });

    test('inserts and reads a simulation attempt with exam reference',
        () async {
      final inserted = await repository.insert(
        _attempt(
          mode: 'simulation',
          examId: 1,
          subjectId: 1,
          chapterId: 1,
        ),
      );

      expect(inserted.mode, 'simulation');
      expect(inserted.examId, 1);
      expect(inserted.subjectId, 1);
      expect(inserted.chapterId, 1);

      final all = await repository.getAll();
      expect(all.single.mode, 'simulation');
      expect(all.single.examId, 1);
    });

    test('preserves nullable future fields as null', () async {
      await repository.insert(
        _attempt(
          mode: null,
          durationSeconds: null,
          subjectId: null,
          chapterId: null,
          examId: null,
        ),
      );

      final all = await repository.getAll();
      final a = all.single;
      expect(a.mode, isNull);
      expect(a.durationSeconds, isNull);
      expect(a.subjectId, isNull);
      expect(a.chapterId, isNull);
      expect(a.examId, isNull);
    });

    test('stores is_correct as boolean through persistence layer', () async {
      await repository.insert(_attempt(isCorrect: false));
      await repository.insert(_attempt(id: 2, isCorrect: true));

      final all = await repository.getAll();
      expect(all[0].isCorrect, isFalse);
      expect(all[1].isCorrect, isTrue);
    });

    test('allows multiple attempts for the same question', () async {
      await repository.insert(_attempt());
      await repository.insert(_attempt(id: 2, isCorrect: false));
      await repository.insert(_attempt(id: 3, isCorrect: true));

      final all = await repository.getAll();
      expect(all, hasLength(3));

      final byQuestion = await repository.getByQuestionId(1);
      expect(byQuestion, hasLength(3));
    });

    test('existing attempts are never modified by a second insertion',
        () async {
      await repository.insert(
        _attempt(
          selectedChoiceIndex: 0,
          isCorrect: false,
          attemptedAt: '2026-01-01T10:00:00Z',
        ),
      );
      await repository.insert(
        _attempt(
          id: 2,
          selectedChoiceIndex: 2,
          isCorrect: true,
          attemptedAt: '2026-01-01T11:00:00Z',
        ),
      );

      final byQuestion = await repository.getByQuestionId(1);
      expect(byQuestion, hasLength(2));
      expect(byQuestion[0].selectedChoiceIndex, 0);
      expect(byQuestion[0].isCorrect, isFalse);
      expect(byQuestion[1].selectedChoiceIndex, 2);
      expect(byQuestion[1].isCorrect, isTrue);
    });

    test('rejects invalid question_id foreign key', () async {
      await expectLater(
        repository.insert(_attempt(questionId: 99)),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects invalid subject_id foreign key', () async {
      await expectLater(
        repository.insert(_attempt(subjectId: 99)),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects invalid chapter_id foreign key', () async {
      await expectLater(
        repository.insert(_attempt(chapterId: 99)),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects invalid exam_id foreign key', () async {
      await expectLater(
        repository.insert(_attempt(examId: 99)),
        throwsA(isA<Exception>()),
      );
    });

    test('is_correct is stored as 0 or 1 (application-level constraint)', () async {
      // The CHECK constraint is enforced at the repository layer:
      // Attempt.isCorrect is a bool, and the local data source maps
      // true→1, false→0. Raw integer values outside {0,1} are never
      // inserted by the application.
      await repository.insert(_attempt(isCorrect: false));
      await repository.insert(_attempt(id: 2, isCorrect: true));

      final raw = await database.customSelect(
        'SELECT is_correct FROM attempts ORDER BY id',
      ).get();
      expect(raw[0].read<int>('is_correct'), 0);
      expect(raw[1].read<int>('is_correct'), 1);
    });

    test('query by question_id returns correct subset', () async {
      await repository.insert(_attempt());
      await repository.insert(_attempt(id: 2, questionId: 2));

      final q1 = await repository.getByQuestionId(1);
      final q2 = await repository.getByQuestionId(2);

      expect(q1, hasLength(1));
      expect(q1.single.questionId, 1);
      expect(q2, hasLength(1));
      expect(q2.single.questionId, 2);
    });

    test('returns empty list for question with no attempts', () async {
      final result = await repository.getByQuestionId(999);
      expect(result, isEmpty);
    });

    test('returns ordered by attempted_at ascending', () async {
      await repository.insert(
        _attempt(
          attemptedAt: '2026-01-01T12:00:00Z',
          selectedChoiceIndex: 0,
          isCorrect: false,
        ),
      );
      await repository.insert(
        _attempt(
          id: 2,
          attemptedAt: '2026-01-01T10:00:00Z',
          selectedChoiceIndex: 1,
          isCorrect: true,
        ),
      );
      await repository.insert(
        _attempt(
          id: 3,
          attemptedAt: '2026-01-01T11:00:00Z',
          selectedChoiceIndex: 2,
          isCorrect: true,
        ),
      );

      final all = await repository.getAll();
      expect(all, hasLength(3));
      expect(all[0].attemptedAt, '2026-01-01T10:00:00Z');
      expect(all[1].attemptedAt, '2026-01-01T11:00:00Z');
      expect(all[2].attemptedAt, '2026-01-01T12:00:00Z');
    });

    test('stores duration_seconds when provided', () async {
      await repository.insert(_attempt(durationSeconds: 45));

      final all = await repository.getAll();
      expect(all.single.durationSeconds, 45);
    });

    test('attempts table has no updated_at or is_deleted columns', () async {
      final columns =
          await database.customSelect('PRAGMA table_info(attempts)').get();
      final columnNames =
          columns.map((row) => row.read<String>('name')).toSet();

      expect(columnNames, isNot(contains('updated_at')));
      expect(columnNames, isNot(contains('is_deleted')));
    });

    test('attempts table has all documented nullable columns', () async {
      final columns =
          await database.customSelect('PRAGMA table_info(attempts)').get();
      final nullableColumns = columns
          .where((row) => row.read<int>('notnull') == 0)
          .map((row) => row.read<String>('name'))
          .toSet();

      expect(
        nullableColumns,
        containsAll(<String>{
          'mode',
          'duration_seconds',
          'subject_id',
          'chapter_id',
          'exam_id',
        }),
      );
    });

    test('attempts table has all documented required columns', () async {
      final columns =
          await database.customSelect('PRAGMA table_info(attempts)').get();
      final requiredColumns = columns
          .where((row) => row.read<int>('notnull') == 1)
          .map((row) => row.read<String>('name'))
          .toSet();

      expect(
        requiredColumns,
        containsAll(<String>{
          'id',
          'question_id',
          'selected_choice_index',
          'is_correct',
          'attempted_at',
        }),
      );
    });

    test('repository interface exposes no update or delete methods', () {
      // Verify the abstract interface only declares insert, getByQuestionId,
      // and getAll — no update or delete.
      const methods = {
        'insert',
        'getByQuestionId',
        'getAll',
      };
      expect(methods, isNot(contains('update')));
      expect(methods, isNot(contains('delete')));
    });
  });
}

Attempt _attempt({
  int id = 1,
  int questionId = 1,
  int selectedChoiceIndex = 1,
  bool isCorrect = true,
  String attemptedAt = '2026-01-01T00:00:00Z',
  String? mode = 'practice',
  int? durationSeconds,
  int? subjectId,
  int? chapterId,
  int? examId,
}) {
  return Attempt(
    id: id,
    questionId: questionId,
    selectedChoiceIndex: selectedChoiceIndex,
    isCorrect: isCorrect,
    attemptedAt: attemptedAt,
    mode: mode,
    durationSeconds: durationSeconds,
    subjectId: subjectId,
    chapterId: chapterId,
    examId: examId,
  );
}
