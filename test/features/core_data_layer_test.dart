import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/grades/data/local_data_sources/grade_local_data_source.dart';
import 'package:euee_prep/features/grades/data/repositories/grade_repository_impl.dart';
import 'package:euee_prep/features/grades/domain/models/grade.dart';
import 'package:euee_prep/features/streams/data/local_data_sources/stream_local_data_source.dart';
import 'package:euee_prep/features/streams/data/repositories/stream_repository_impl.dart';
import 'package:euee_prep/features/streams/domain/models/stream_model.dart';
import 'package:euee_prep/features/subjects/data/local_data_sources/subject_local_data_source.dart';
import 'package:euee_prep/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:euee_prep/features/subjects/domain/models/subject.dart';

void main() {
  late db.AppDatabase database;

  test('migrates an empty v1 database to v12', () async {
    final oldDatabase = db.AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDatabase) {
          rawDatabase.execute('PRAGMA user_version = 1');
        },
      ),
    );

    await oldDatabase.customSelect('SELECT 1').get();

    expect(oldDatabase.schemaVersion, 12);
    expect(
        oldDatabase.allTables.map((table) => table.actualTableName),
        containsAll(<String>[
          'grades',
          'streams',
          'subjects',
          'content_packs',
          'chapters',
          'topics',
          'questions',
          'question_topics',
          'exams',
          'exam_questions',
          'resources',
          'attempts',
          'install_identities',
          'entitlements',
          'payment_requests',
          'settings',
        ]));
    await oldDatabase.close();
  });

  group('repositories', () {
    setUp(() {
      database = db.AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('enforces Grade level and Stream slug uniqueness', () async {
      final gradeRepository =
          GradeRepositoryImpl(GradeLocalDataSource(database));
      final streamRepository =
          StreamRepositoryImpl(StreamLocalDataSource(database));

      await gradeRepository.insert(const Grade(id: 1, level: 9));
      await streamRepository.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );

      await expectLater(
        gradeRepository.insert(const Grade(id: 2, level: 9)),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        streamRepository.insert(
          const StreamModel(id: 2, slug: 'natural_science'),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('inserts and reads Grade through its repository', () async {
      final repository = GradeRepositoryImpl(GradeLocalDataSource(database));

      final inserted = await repository.insert(const Grade(id: 1, level: 11));
      final grades = await repository.getAll();

      expect(inserted.level, 11);
      expect(grades, hasLength(1));
      expect(grades.single.id, 1);
      expect(grades.single.level, 11);
    });

    test('inserts and reads Stream through its repository', () async {
      final repository = StreamRepositoryImpl(StreamLocalDataSource(database));

      final inserted = await repository.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );
      final streams = await repository.getAll();

      expect(inserted.slug, 'natural_science');
      expect(streams, hasLength(1));
      expect(streams.single.id, 1);
      expect(streams.single.slug, 'natural_science');
    });

    test('inserts and reads Subject through its repository', () async {
      await database.into(database.streams).insert(
            const db.StreamsCompanion(
              id: drift.Value(1),
              slug: drift.Value('natural_science'),
            ),
          );
      final repository =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));

      final inserted = await repository.insert(
        const Subject(
          id: 1,
          streamId: 1,
          slug: 'physics',
          title: 'Physics',
        ),
      );
      final subjects = await repository.getAll();

      expect(inserted, isA<Subject>());
      expect(subjects.single.streamId, 1);
      expect(subjects.single.slug, 'physics');
      expect(subjects.single.title, 'Physics');
    });

    test('enforces subject stream foreign key and per-stream slug uniqueness',
        () async {
      await database.into(database.streams).insert(
            const db.StreamsCompanion(
              id: drift.Value(1),
              slug: drift.Value('natural_science'),
            ),
          );
      final repository =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));
      const subject = Subject(
        id: 1,
        streamId: 1,
        slug: 'physics',
        title: 'Physics',
      );

      await repository.insert(subject);

      await expectLater(
        repository.insert(
          const Subject(
            id: 2,
            streamId: 99,
            slug: 'chemistry',
            title: 'Chemistry',
          ),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repository.insert(
          const Subject(
            id: 3,
            streamId: 1,
            slug: 'physics',
            title: 'Physics duplicate',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('maps persistence rows to independent domain objects', () async {
      await database.into(database.streams).insert(
            const db.StreamsCompanion(
              id: drift.Value(1),
              slug: drift.Value('social_science'),
            ),
          );
      final repository =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));

      final subject = await repository.insert(
        const Subject(
          id: 7,
          streamId: 1,
          slug: 'history',
          title: 'History',
        ),
      );

      expect(subject.runtimeType.toString(), 'Subject');
      expect(subject.id, 7);
      expect(subject.title, 'History');
    });
  });
}
