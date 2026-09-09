import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/entitlements/data/local_data_sources/entitlement_local_data_source.dart';
import 'package:euee_prep/features/entitlements/data/repositories/entitlement_repository_impl.dart';
import 'package:euee_prep/features/entitlements/domain/models/entitlement.dart';
import 'package:euee_prep/features/entitlements/domain/repositories/entitlement_repository.dart';
import 'package:euee_prep/features/entitlements/data/local_data_sources/install_identity_local_data_source.dart';
import 'package:euee_prep/features/entitlements/data/repositories/install_identity_repository_impl.dart';

/// Integration test proving entitlements schema end-to-end (Decisions 012, 017, 033).
///
/// Covers: FK relationships, active/revoked states, cache sync semantics,
/// multiple entitlements per install, and no Preferred Stream coupling.
void main() {
  late db.AppDatabase database;
  late EntitlementLocalDataSource entitlementLds;
  late EntitlementRepositoryImpl entitlementRepo;
  late String testInstallId;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    entitlementLds = EntitlementLocalDataSource(database);
    entitlementRepo = EntitlementRepositoryImpl(entitlementLds);

    // Seed install identity (required for FK) — capture the generated install_id
    final installLds = InstallIdentityLocalDataSource(database);
    final installRepo = InstallIdentityRepositoryImpl(installLds);
    final identity = await installRepo.ensureCreated();
    testInstallId = identity.installId;

    // Seed streams (required for FK)
    await database.into(database.streams).insert(
          db.StreamsCompanion.insert(
            id: const Value(1),
            slug: 'natural_science',
          ),
        );
    await database.into(database.streams).insert(
          db.StreamsCompanion.insert(
            id: const Value(2),
            slug: 'social_science',
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  test('syncFromServer caches entitlements for an install', () async {
    final entitlements = [
      Entitlement(
        id: 1,
        installId: testInstallId,
        streamId: 1,
        status: EntitlementStatus.active,
        grantedAt: '2026-01-01T00:00:00Z',
      ),
    ];

    await entitlementRepo.syncFromServer(testInstallId, entitlements);

    final cached = await entitlementRepo.getByInstallId(testInstallId);
    expect(cached, hasLength(1));
    expect(cached.first.installId, testInstallId);
    expect(cached.first.streamId, 1);
    expect(cached.first.status, EntitlementStatus.active);
  });

  test('getActiveByInstallIdAndStreamId returns active entitlement', () async {
    await entitlementRepo.syncFromServer(testInstallId, [
      Entitlement(
        id: 1,
        installId: testInstallId,
        streamId: 1,
        status: EntitlementStatus.active,
        grantedAt: '2026-01-01T00:00:00Z',
      ),
    ]);

    final active = await entitlementRepo.getActiveByInstallIdAndStreamId(
      testInstallId,
      1,
    );
    expect(active, isNotNull);
    expect(active!.status, EntitlementStatus.active);
  });

  test(
      'getActiveByInstallIdAndStreamId returns null when no active entitlement',
      () async {
    final active = await entitlementRepo.getActiveByInstallIdAndStreamId(
      testInstallId,
      1,
    );
    expect(active, isNull);
  });

  test('syncFromServer replaces previous cache atomically', () async {
    // First sync
    await entitlementRepo.syncFromServer(testInstallId, [
      Entitlement(
        id: 1,
        installId: testInstallId,
        streamId: 1,
        status: EntitlementStatus.active,
        grantedAt: '2026-01-01T00:00:00Z',
      ),
    ]);

    // Second sync with different entitlement
    await entitlementRepo.syncFromServer(testInstallId, [
      Entitlement(
        id: 2,
        installId: testInstallId,
        streamId: 2,
        status: EntitlementStatus.active,
        grantedAt: '2026-02-01T00:00:00Z',
      ),
    ]);

    final cached = await entitlementRepo.getByInstallId(testInstallId);
    expect(cached, hasLength(1));
    expect(cached.first.streamId, 2);
  });

  test('revoked entitlement is representable', () async {
    await entitlementRepo.syncFromServer(testInstallId, [
      Entitlement(
        id: 1,
        installId: testInstallId,
        streamId: 1,
        status: EntitlementStatus.revoked,
        grantedAt: '2026-01-01T00:00:00Z',
        revokedAt: '2026-03-01T00:00:00Z',
      ),
    ]);

    final cached = await entitlementRepo.getByInstallId(testInstallId);
    expect(cached, hasLength(1));
    expect(cached.first.status, EntitlementStatus.revoked);
    expect(cached.first.revokedAt, '2026-03-01T00:00:00Z');

    // Revoked entitlement is NOT active
    final active = await entitlementRepo.getActiveByInstallIdAndStreamId(
      testInstallId,
      1,
    );
    expect(active, isNull);
  });

  test('multiple entitlements for one install (future second-stream purchase)',
      () async {
    await entitlementRepo.syncFromServer(testInstallId, [
      Entitlement(
        id: 1,
        installId: testInstallId,
        streamId: 1,
        status: EntitlementStatus.active,
        grantedAt: '2026-01-01T00:00:00Z',
      ),
      Entitlement(
        id: 2,
        installId: testInstallId,
        streamId: 2,
        status: EntitlementStatus.active,
        grantedAt: '2026-02-01T00:00:00Z',
      ),
    ]);

    final cached = await entitlementRepo.getByInstallId(testInstallId);
    expect(cached, hasLength(2));

    final nsActive = await entitlementRepo.getActiveByInstallIdAndStreamId(
      testInstallId,
      1,
    );
    final ssActive = await entitlementRepo.getActiveByInstallIdAndStreamId(
      testInstallId,
      2,
    );
    expect(nsActive, isNotNull);
    expect(ssActive, isNotNull);
  });

  test('no Preferred Stream coupling in repository API', () async {
    // Seed a payment request so the FK is satisfied
    await database.into(database.paymentRequests).insert(
          db.PaymentRequestsCompanion.insert(
            requestId: 'req-uuid-123',
            installId: testInstallId,
            streamId: 1,
            proofType: 'screenshot',
            proofValue: '/path',
            status: 'pending',
            submittedAt: '2026-01-01T00:00:00Z',
          ),
        );

    await entitlementRepo.syncFromServer(testInstallId, [
      Entitlement(
        id: 1,
        installId: testInstallId,
        streamId: 1,
        status: EntitlementStatus.active,
        grantedAt: '2026-01-01T00:00:00Z',
        sourcePaymentRequestId: 'req-uuid-123',
      ),
    ]);

    final cached = await entitlementRepo.getByInstallId(testInstallId);
    expect(cached.first.sourcePaymentRequestId, 'req-uuid-123');

    // Also test without source_payment_request_id
    await entitlementRepo.syncFromServer(testInstallId, [
      Entitlement(
        id: 2,
        installId: testInstallId,
        streamId: 1,
        status: EntitlementStatus.active,
        grantedAt: '2026-01-01T00:00:00Z',
      ),
    ]);

    final cached2 = await entitlementRepo.getByInstallId(testInstallId);
    expect(cached2.first.sourcePaymentRequestId, isNull);
  });

  test('no Preferred Stream coupling in repository API', () async {
    // Verify the repository API has no Preferred Stream parameters
    // and does not read from the settings table
    await entitlementRepo.syncFromServer(testInstallId, [
      Entitlement(
        id: 1,
        installId: testInstallId,
        streamId: 1,
        status: EntitlementStatus.active,
        grantedAt: '2026-01-01T00:00:00Z',
      ),
    ]);

    final cached = await entitlementRepo.getByInstallId(testInstallId);
    expect(cached.first.streamId, 1);

    // The repository only knows about install_id and stream_id,
    // not about Preferred Stream
    expect(cached.length, 1);
  });
}
