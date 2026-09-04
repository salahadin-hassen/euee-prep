import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/content/data/local_data_sources/resource_local_data_source.dart';
import 'package:euee_prep/features/content/data/repositories/resource_repository_impl.dart';
import 'package:euee_prep/features/content/domain/models/resource.dart';

void main() {
  late db.AppDatabase database;
  late ResourceRepositoryImpl repository;

  test('migrates a v6 database to v8 with Resource table', () async {
    final oldDatabase = db.AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDatabase) {
          rawDatabase.execute('PRAGMA user_version = 6');
        },
      ),
    );

    await oldDatabase.customSelect('SELECT 1').get();

    expect(oldDatabase.schemaVersion, 8);
    expect(
      oldDatabase.allTables.map((table) => table.actualTableName),
      contains('resources'),
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
              packLocalId: drift.Value('ch-1'),
              title: drift.Value('Mechanics'),
              orderIndex: drift.Value(0),
            ),
          );
      await database.into(database.topics).insert(
            const db.TopicsCompanion(
              id: drift.Value(1),
              chapterId: drift.Value(1),
              sourcePackId: drift.Value('pack-1'),
              packLocalId: drift.Value('topic-1'),
              title: drift.Value('Newton\'s Laws'),
              orderIndex: drift.Value(0),
            ),
          );
      repository = ResourceRepositoryImpl(ResourceLocalDataSource(database));
    });

    tearDown(() async {
      await database.close();
    });

    test('inserts and reads a resource with correct ordering', () async {
      final note = _resource(id: 1, type: ResourceType.note, orderIndex: 0);
      final flashcard =
          _resource(id: 2, type: ResourceType.flashcard, orderIndex: 1);
      final mindmap =
          _resource(id: 3, type: ResourceType.mindmap, orderIndex: 2);

      await repository.insert(note);
      await repository.insert(flashcard);
      await repository.insert(mindmap);

      final results = await repository.getByTopicId(1);

      expect(results, hasLength(3));
      expect(results[0].type, ResourceType.note);
      expect(results[1].type, ResourceType.flashcard);
      expect(results[2].type, ResourceType.mindmap);
    });

    test('enforces topic foreign key', () async {
      final badResource = _resource(id: 1, topicId: 99);

      await expectLater(
        repository.insert(badResource),
        throwsA(isA<Exception>()),
      );
    });

    test('enforces source_pack_id foreign key', () async {
      final badResource = _resource(id: 1, sourcePackId: 'missing');

      await expectLater(
        repository.insert(badResource),
        throwsA(isA<Exception>()),
      );
    });

    test('enforces pack_local_id uniqueness within a source pack', () async {
      await repository.insert(_resource(id: 1));

      await expectLater(
        repository.insert(_resource(id: 2, packLocalId: 'resource-1')),
        throwsA(isA<Exception>()),
      );
    });

    test('returns empty list for a topic with no resources', () async {
      final results = await repository.getByTopicId(999);
      expect(results, isEmpty);
    });

    test('preserves nullable title', () async {
      await repository.insert(_resource(id: 1, title: null));
      await repository.insert(_resource(id: 2, title: 'Study Guide'));

      final results = await repository.getByTopicId(1);

      expect(results[0].title, isNull);
      expect(results[1].title, 'Study Guide');
    });
  });
}

Resource _resource({
  int id = 1,
  int topicId = 1,
  String sourcePackId = 'pack-1',
  String? packLocalId,
  ResourceType type = ResourceType.note,
  String content = '# Topic notes',
  int orderIndex = 0,
  String? title = 'Notes',
}) {
  return Resource(
    id: id,
    topicId: topicId,
    sourcePackId: sourcePackId,
    packLocalId: packLocalId ?? 'resource-$id',
    type: type,
    content: content,
    orderIndex: orderIndex,
    title: title,
  );
}
