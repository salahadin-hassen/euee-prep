import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/content/data/local_data_sources/chapter_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/topic_local_data_source.dart';
import 'package:euee_prep/features/content/data/repositories/chapter_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/topic_repository_impl.dart';
import 'package:euee_prep/features/content/domain/models/chapter.dart';
import 'package:euee_prep/features/content/domain/models/topic.dart';

void main() {
  late db.AppDatabase database;
  late ChapterRepositoryImpl chapterRepository;
  late TopicRepositoryImpl topicRepository;

  test('migrates a v4 database to v5 with existing Chapter and Topic tables',
      () async {
    final oldDatabase = db.AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDatabase) {
          rawDatabase.execute('PRAGMA user_version = 4');
        },
      ),
    );

    await oldDatabase.customSelect('SELECT 1').get();

    expect(oldDatabase.schemaVersion, 5);
    expect(
      oldDatabase.allTables.map((table) => table.actualTableName),
      containsAll(<String>['chapters', 'topics']),
    );
    await oldDatabase.close();
  });

  group('repositories', () {
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
      chapterRepository = ChapterRepositoryImpl(
        ChapterLocalDataSource(database),
      );
      topicRepository = TopicRepositoryImpl(TopicLocalDataSource(database));
    });

    tearDown(() async {
      await database.close();
    });

    test('inserts and reads Chapter with its documented relationships',
        () async {
      final inserted = await chapterRepository.insert(_chapter());
      final chapters = await chapterRepository.getAll();

      expect(inserted, isA<Chapter>());
      expect(chapters, hasLength(1));
      expect(chapters.single.subjectId, 1);
      expect(chapters.single.gradeId, 1);
      expect(chapters.single.sourcePackId, 'pack-1');
      expect(chapters.single.packLocalId, 'chapter-1');
      expect(chapters.single.orderIndex, 3);
    });

    test('inserts and reads Topic through its Chapter relationship', () async {
      await chapterRepository.insert(_chapter());

      final inserted = await topicRepository.insert(_topic());
      final topics = await topicRepository.getAll();

      expect(inserted, isA<Topic>());
      expect(topics, hasLength(1));
      expect(topics.single.chapterId, 1);
      expect(topics.single.sourcePackId, 'pack-1');
      expect(topics.single.packLocalId, 'topic-1');
      expect(topics.single.orderIndex, 2);
    });

    test('rejects invalid Chapter and Topic foreign keys', () async {
      await expectLater(
        chapterRepository.insert(_chapter(subjectId: 99)),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        chapterRepository.insert(_chapter(gradeId: 99)),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        chapterRepository.insert(_chapter(sourcePackId: 'missing-pack')),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        topicRepository.insert(_topic(chapterId: 99)),
        throwsA(isA<Exception>()),
      );
    });

    test('enforces pack-local identity uniqueness for both entities', () async {
      await chapterRepository.insert(_chapter());
      await topicRepository.insert(_topic());

      await expectLater(
        chapterRepository.insert(_chapter(id: 2)),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        topicRepository.insert(_topic(id: 2)),
        throwsA(isA<Exception>()),
      );
    });

    test('requires all non-primary-key Chapter and Topic columns', () async {
      final chapterColumns =
          await database.customSelect('PRAGMA table_info(chapters)').get();
      final topicColumns =
          await database.customSelect('PRAGMA table_info(topics)').get();

      for (final row in [...chapterColumns, ...topicColumns]) {
        if (row.read<String>('name') != 'id') {
          expect(row.read<int>('notnull'), 1);
        }
      }
    });
  });
}

Chapter _chapter({
  int id = 1,
  int subjectId = 1,
  int gradeId = 1,
  String sourcePackId = 'pack-1',
}) {
  return Chapter(
    id: id,
    subjectId: subjectId,
    gradeId: gradeId,
    sourcePackId: sourcePackId,
    packLocalId: 'chapter-1',
    title: 'Mechanics',
    orderIndex: 3,
  );
}

Topic _topic({int id = 1, int chapterId = 1}) {
  return Topic(
    id: id,
    chapterId: chapterId,
    sourcePackId: 'pack-1',
    packLocalId: 'topic-1',
    title: 'Motion',
    orderIndex: 2,
  );
}
