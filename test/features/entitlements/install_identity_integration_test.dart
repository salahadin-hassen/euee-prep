import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/entitlements/data/local_data_sources/install_identity_local_data_source.dart';
import 'package:euee_prep/features/entitlements/data/models/install_identity_persistence_model.dart';
import 'package:euee_prep/features/entitlements/data/repositories/install_identity_repository_impl.dart';

/// Integration test proving install_identity schema end-to-end (Decision 032).
///
/// Covers: singleton generation, idempotency, get-before-create returns null,
/// UNIQUE constraint on install_id, and persistence across repository instances.
void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('first-launch generation creates singleton install identity', () async {
    final lds = InstallIdentityLocalDataSource(database);
    final repo = InstallIdentityRepositoryImpl(lds);

    final first = await repo.ensureCreated();
    expect(first.installId, isNotEmpty);
    expect(first.createdAt, isNotEmpty);

    // Verify UUID v4 format (8-4-4-4-12 hex segments)
    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(uuidPattern.hasMatch(first.installId), isTrue);

    // Verify only one row exists
    final allRows = await database.select(database.installIdentities).get();
    expect(allRows, hasLength(1));
  });

  test('ensureCreated is idempotent', () async {
    final lds = InstallIdentityLocalDataSource(database);
    final repo = InstallIdentityRepositoryImpl(lds);

    final first = await repo.ensureCreated();
    final second = await repo.ensureCreated();
    expect(second.installId, first.installId);
    expect(second.createdAt, first.createdAt);

    // Still exactly one row
    final allRows = await database.select(database.installIdentities).get();
    expect(allRows, hasLength(1));
  });

  test('get() returns null before first ensureCreated()', () async {
    final lds = InstallIdentityLocalDataSource(database);
    final repo = InstallIdentityRepositoryImpl(lds);

    final result = await repo.get();
    expect(result, isNull);
  });

  test('get() returns identity after ensureCreated()', () async {
    final lds = InstallIdentityLocalDataSource(database);
    final repo = InstallIdentityRepositoryImpl(lds);

    final created = await repo.ensureCreated();
    final retrieved = await repo.get();
    expect(retrieved, isNotNull);
    expect(retrieved!.installId, created.installId);
  });

  test('insert directly rejects duplicate install_id', () async {
    final lds = InstallIdentityLocalDataSource(database);

    await lds.insert(
      InstallIdentityPersistenceModel(
        id: 1,
        installId: 'test-uuid-1',
        createdAt: '2026-01-01T00:00:00Z',
      ),
    );

    // Second insert with different id but same install_id must fail
    // (UNIQUE constraint on install_id)
    expect(
      () => lds.insert(
        InstallIdentityPersistenceModel(
          id: 2,
          installId: 'test-uuid-1',
          createdAt: '2026-01-01T00:00:00Z',
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('install identity persists across repository instances', () async {
    final lds1 = InstallIdentityLocalDataSource(database);
    final repo1 = InstallIdentityRepositoryImpl(lds1);
    final first = await repo1.ensureCreated();

    // Simulate app restart: new repository instance on same database
    final lds2 = InstallIdentityLocalDataSource(database);
    final repo2 = InstallIdentityRepositoryImpl(lds2);
    final second = await repo2.get();
    expect(second, isNotNull);
    expect(second!.installId, first.installId);
  });
}
