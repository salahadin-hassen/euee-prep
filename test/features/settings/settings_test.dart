import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/entitlements/data/local_data_sources/entitlement_local_data_source.dart';
import 'package:euee_prep/features/entitlements/data/local_data_sources/install_identity_local_data_source.dart';
import 'package:euee_prep/features/entitlements/data/repositories/entitlement_repository_impl.dart';
import 'package:euee_prep/features/entitlements/data/repositories/install_identity_repository_impl.dart';
import 'package:euee_prep/features/entitlements/domain/models/entitlement.dart';
import 'package:euee_prep/features/entitlements/domain/repositories/install_identity_repository.dart';
import 'package:euee_prep/features/streams/data/local_data_sources/stream_local_data_source.dart';
import 'package:euee_prep/features/streams/data/repositories/stream_repository_impl.dart';
import 'package:euee_prep/features/streams/domain/models/stream_model.dart';

void main() {
  late db.AppDatabase database;
  late StreamRepositoryImpl streamRepo;
  late InstallIdentityRepository installIdRepo;
  late EntitlementRepositoryImpl entitlementRepo;
  late String installId;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
    installIdRepo = InstallIdentityRepositoryImpl(
      InstallIdentityLocalDataSource(database),
    );
    entitlementRepo = EntitlementRepositoryImpl(
      EntitlementLocalDataSource(database),
    );

    await streamRepo.insert(
      const StreamModel(id: 1, slug: 'natural_science'),
    );
    await streamRepo.insert(
      const StreamModel(id: 2, slug: 'social_science'),
    );

    final identity = await installIdRepo.ensureCreated();
    installId = identity.installId;
  });

  tearDown(() async {
    await database.close();
  });

  group('settings - change Preferred Stream', () {
    test('can set Preferred Stream when entitled stream is selected', () async {
      await entitlementRepo.syncFromServer(installId, [
        Entitlement(
          id: 1,
          installId: installId,
          streamId: 1,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
      ]);

      await database.setSetting('preferred_stream_id', '1');
      final result = await database.getSetting('preferred_stream_id');
      expect(result, '1');
    });

    test('Preferred Stream changes without changing Entitlement', () async {
      await entitlementRepo.syncFromServer(installId, [
        Entitlement(
          id: 1,
          installId: installId,
          streamId: 1,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
      ]);

      await database.setSetting('preferred_stream_id', '2');

      final nsEntitlement =
          await entitlementRepo.getActiveByInstallIdAndStreamId(
        installId,
        1,
      );
      final ssEntitlement =
          await entitlementRepo.getActiveByInstallIdAndStreamId(
        installId,
        2,
      );
      expect(nsEntitlement, isNotNull);
      expect(ssEntitlement, isNull);

      final preferred = await database.getSetting('preferred_stream_id');
      expect(preferred, '2');
    });

    test('can reset Preferred Stream', () async {
      await database.setSetting('preferred_stream_id', '1');
      await database.setSetting('preferred_stream_id', '');
      final result = await database.getSetting('preferred_stream_id');
      expect(result, '');
    });

    test('stream list loads correctly for settings', () async {
      final streams = await streamRepo.getAll();
      expect(streams, hasLength(2));
      expect(
        streams.map((s) => s.slug).toList(),
        containsAll(['natural_science', 'social_science']),
      );
    });
  });

  group('settings - entitlement separation', () {
    test('setting Preferred Stream does not grant or revoke entitlement',
        () async {
      await entitlementRepo.syncFromServer(installId, [
        Entitlement(
          id: 1,
          installId: installId,
          streamId: 1,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
      ]);

      // Change preferred stream
      await database.setSetting('preferred_stream_id', '2');

      // Entitlement should still be for stream 1 only
      final nsEntitlement =
          await entitlementRepo.getActiveByInstallIdAndStreamId(
        installId,
        1,
      );
      expect(nsEntitlement, isNotNull);
      expect(nsEntitlement!.status, EntitlementStatus.active);

      final ssEntitlement =
          await entitlementRepo.getActiveByInstallIdAndStreamId(
        installId,
        2,
      );
      expect(ssEntitlement, isNull);
    });

    test(
        'setting Preferred Stream to unentitled stream does not unlock content',
        () async {
      // Only stream 1 is entitled
      await entitlementRepo.syncFromServer(installId, [
        Entitlement(
          id: 1,
          installId: installId,
          streamId: 1,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
      ]);

      // Change preferred stream to stream 2 (not entitled)
      await database.setSetting('preferred_stream_id', '2');

      // Stream 2 should still not have an entitlement
      final ssEntitlement =
          await entitlementRepo.getActiveByInstallIdAndStreamId(
        installId,
        2,
      );
      expect(ssEntitlement, isNull);
    });
  });
}
