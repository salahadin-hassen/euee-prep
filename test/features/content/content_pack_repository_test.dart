import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/content/data/local_data_sources/content_pack_local_data_source.dart';
import 'package:euee_prep/features/content/data/repositories/content_pack_repository_impl.dart';
import 'package:euee_prep/features/content/domain/models/content_pack.dart';

void main() {
  late db.AppDatabase database;
  late ContentPackRepositoryImpl repository;

  test('migrates a v5 database to v8 with Exam prerequisites', () async {
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
      contains('content_packs'),
    );
    await oldDatabase.close();
  });

  group('repository', () {
    setUp(() async {
      database = db.AppDatabase.forTesting(NativeDatabase.memory());
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
      repository = ContentPackRepositoryImpl(
        ContentPackLocalDataSource(database),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('inserts, reads, and maps a ContentPack', () async {
      final inserted = await repository.insert(_pack());
      final packs = await repository.getAll();

      expect(inserted, isA<ContentPack>());
      expect(packs, hasLength(1));
      expect(packs.single.id, 'natural_science-physics#1.0.0');
      expect(packs.single.packKey, 'natural_science-physics');
      expect(packs.single.subjectId, 1);
      expect(packs.single.checksum, 'sha256:one');
    });

    test('returns the newest imported version for a pack key', () async {
      await repository.insert(_pack());
      await repository.insert(
        _pack(
          id: 'natural_science-physics#1.1.0',
          packVersion: '1.1.0',
          checksum: 'sha256:two',
          importedAt: '2026-02-01T00:00:00Z',
        ),
      );

      final latest =
          await repository.getLatestForPackKey('natural_science-physics');

      expect(latest?.packVersion, '1.1.0');
      expect(latest?.checksum, 'sha256:two');
    });

    test('enforces subject foreign key and pack identity uniqueness', () async {
      await expectLater(
        repository.insert(_pack(subjectId: 99)),
        throwsA(isA<Exception>()),
      );
      await repository.insert(_pack());

      await expectLater(
        repository.insert(_pack(id: 'different-id')),
        throwsA(isA<Exception>()),
      );
    });

    test('requires all metadata columns to be non-null', () async {
      final columns =
          await database.customSelect('PRAGMA table_info(content_packs)').get();
      final nullableColumns = columns
          .where((row) => row.read<int>('notnull') == 0)
          .map((row) => row.read<String>('name'));

      expect(nullableColumns, isEmpty);
    });
  });
}

ContentPack _pack({
  String id = 'natural_science-physics#1.0.0',
  String packVersion = '1.0.0',
  String checksum = 'sha256:one',
  String importedAt = '2026-01-01T00:00:00Z',
  int subjectId = 1,
}) {
  return ContentPack(
    id: id,
    packKey: 'natural_science-physics',
    subjectId: subjectId,
    packVersion: packVersion,
    schemaVersion: '2',
    generatedAt: '2025-12-01T00:00:00Z',
    checksum: checksum,
    minimumAppVersion: '0.1.0',
    importedAt: importedAt,
  );
}
