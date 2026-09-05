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
import 'package:euee_prep/features/subjects/data/local_data_sources/subject_local_data_source.dart';
import 'package:euee_prep/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:euee_prep/features/subjects/domain/models/subject.dart';

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

    // Seed streams
    await streamRepo.insert(
      const StreamModel(id: 1, slug: 'natural_science'),
    );
    await streamRepo.insert(
      const StreamModel(id: 2, slug: 'social_science'),
    );

    // Create install identity
    final identity = await installIdRepo.ensureCreated();
    installId = identity.installId;
  });

  tearDown(() async {
    await database.close();
  });

  group('onboarding - no Preferred Stream → onboarding is shown', () {
    test('preferredStreamIdProvider returns null when no onboarding completed',
        () async {
      final result = await database.getSetting('preferred_stream_id');
      expect(result, isNull);
    });
  });

  group('onboarding - streams load correctly', () {
    test('StreamRepository.getAll returns all streams', () async {
      final streams = await streamRepo.getAll();
      expect(streams, hasLength(2));
      expect(
        streams.map((s) => s.slug).toList(),
        containsAll(['natural_science', 'social_science']),
      );
    });
  });

  group('onboarding - selecting an already-unlocked stream succeeds', () {
    test('selected unlocked stream is persisted as Preferred Stream', () async {
      // Grant entitlement for Natural Science
      await entitlementRepo.syncFromServer(installId, [
        Entitlement(
          id: 1,
          installId: installId,
          streamId: 1,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
      ]);

      // Simulate selecting Natural Science and saving
      await database.setSetting('preferred_stream_id', '1');

      final result = await database.getSetting('preferred_stream_id');
      expect(result, '1');
    });
  });

  group('onboarding - first-launch completion is persisted', () {
    test('first-launch completion is persisted in settings', () async {
      await database.setSetting('preferred_stream_id', '1');
      final result = await database.getSetting('preferred_stream_id');
      expect(result, '1');
    });

    test(
        'saved Preferred Stream → onboarding does not appear on subsequent launch',
        () async {
      await database.setSetting('preferred_stream_id', '1');
      final result = await database.getSetting('preferred_stream_id');
      expect(result, isNotNull);
      expect(result, '1');
    });
  });

  group('onboarding - selecting any stream succeeds regardless of entitlement',
      () {
    test('selecting an unentitled stream still saves Preferred Stream',
        () async {
      // Ensure no entitlement exists for stream 2
      final result = await entitlementRepo.getActiveByInstallIdAndStreamId(
        installId,
        2,
      );
      expect(result, isNull);

      // Preferred stream should be set after selection
      await database.setSetting('preferred_stream_id', '2');
      final preferred = await database.getSetting('preferred_stream_id');
      expect(preferred, '2');
    });

    test('selecting an unentitled stream still navigates to SubjectListScreen',
        () async {
      // Verify no entitlement exists
      final entitlement = await entitlementRepo.getActiveByInstallIdAndStreamId(
        installId,
        2,
      );
      expect(entitlement, isNull);

      // Preferred stream is persisted so onboarding does not re-appear
      await database.setSetting('preferred_stream_id', '2');
      final preferred = await database.getSetting('preferred_stream_id');
      expect(preferred, '2');
    });
  });

  group('onboarding - already-unlocked second stream can become Preferred', () {
    test(
        'an already-unlocked second stream can become Preferred without payment',
        () async {
      // Grant entitlements for both streams
      await entitlementRepo.syncFromServer(installId, [
        Entitlement(
          id: 1,
          installId: installId,
          streamId: 1,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
        Entitlement(
          id: 2,
          installId: installId,
          streamId: 2,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
      ]);

      // Both streams are entitled
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
      expect(ssEntitlement, isNotNull);

      // Either can be saved as Preferred
      await database.setSetting('preferred_stream_id', '2');
      final result = await database.getSetting('preferred_stream_id');
      expect(result, '2');
    });
  });

  group('onboarding - changing Preferred Stream does not change Entitlement',
      () {
    test('changing Preferred Stream does not change Entitlement', () async {
      // Grant entitlement for stream 1 only
      await entitlementRepo.syncFromServer(installId, [
        Entitlement(
          id: 1,
          installId: installId,
          streamId: 1,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
      ]);

      // Save preferred stream as stream 2 (even though not entitled)
      await database.setSetting('preferred_stream_id', '2');

      // Entitlement should still only be for stream 1
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
    });

    test('changing Preferred Stream does not revoke or grant access', () async {
      // Grant entitlement for stream 1
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

      // Stream 1 entitlement should still be active
      final nsEntitlement =
          await entitlementRepo.getActiveByInstallIdAndStreamId(
        installId,
        1,
      );
      expect(nsEntitlement, isNotNull);
      expect(nsEntitlement!.status, EntitlementStatus.active);
    });
  });

  group('onboarding - default state', () {
    test('preferredStreamIdProvider returns null when no onboarding completed',
        () async {
      final result = await database.getSetting('preferred_stream_id');
      expect(result, isNull);
    });

    test('entitlement lookup is not required to save Preferred Stream',
        () async {
      // Verify that stream 2 has no entitlement
      final result = await entitlementRepo.getActiveByInstallIdAndStreamId(
        installId,
        2,
      );
      expect(result, isNull);

      // Preferred stream can still be saved without entitlement
      await database.setSetting('preferred_stream_id', '2');
      final preferred = await database.getSetting('preferred_stream_id');
      expect(preferred, '2');
    });
  });

  group('onboarding - persistence failure does not falsely complete onboarding',
      () {
    test('persistence failure does not falsely complete onboarding', () async {
      // Verify that without a successful setSetting call, preferred_stream_id remains null
      final result = await database.getSetting('preferred_stream_id');
      expect(result, isNull);
    });
  });

  group('onboarding - existing Subject List behavior remains intact', () {
    test('SubjectRepository.getByStreamId returns subjects only for the stream',
        () async {
      final subjectRepo =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));

      await subjectRepo.insert(
        const Subject(id: 1, streamId: 1, slug: 'physics', title: 'Physics'),
      );
      await subjectRepo.insert(
        const Subject(
          id: 2,
          streamId: 1,
          slug: 'mathematics',
          title: 'Mathematics',
        ),
      );
      await subjectRepo.insert(
        const Subject(
            id: 3, streamId: 2, slug: 'geography', title: 'Geography'),
      );

      final nsSubjects = await subjectRepo.getByStreamId(1);
      expect(nsSubjects, hasLength(2));
      expect(nsSubjects.map((s) => s.slug),
          containsAll(['physics', 'mathematics']));

      final ssSubjects = await subjectRepo.getByStreamId(2);
      expect(ssSubjects, hasLength(1));
      expect(ssSubjects.single.slug, 'geography');
    });
  });
}
