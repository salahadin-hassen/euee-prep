import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/core/providers.dart';
import 'package:euee_prep/features/entitlements/data/local_data_sources/entitlement_local_data_source.dart';
import 'package:euee_prep/features/entitlements/data/local_data_sources/install_identity_local_data_source.dart';
import 'package:euee_prep/features/entitlements/data/repositories/entitlement_repository_impl.dart';
import 'package:euee_prep/features/entitlements/data/repositories/install_identity_repository_impl.dart';
import 'package:euee_prep/features/entitlements/domain/models/entitlement.dart';
import 'package:euee_prep/features/entitlements/domain/repositories/entitlement_repository.dart';
import 'package:euee_prep/features/entitlements/domain/repositories/install_identity_repository.dart';
import 'package:euee_prep/features/streams/data/local_data_sources/stream_local_data_source.dart';
import 'package:euee_prep/features/streams/data/repositories/stream_repository_impl.dart';
import 'package:euee_prep/features/streams/domain/models/stream_model.dart';
import 'package:euee_prep/features/subjects/data/local_data_sources/subject_local_data_source.dart';
import 'package:euee_prep/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:euee_prep/features/subjects/domain/models/subject.dart';
import 'package:euee_prep/features/subjects/presentation/subject_list_screen.dart';

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('SubjectRepository.getByStreamId', () {
    test('returns subjects only for the requested stream', () async {
      final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
      final subjectRepo =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));

      await streamRepo.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );
      await streamRepo.insert(
        const StreamModel(id: 2, slug: 'social_science'),
      );

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

    test('returns empty list when no subjects exist for the stream', () async {
      final subjectRepo =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));

      final subjects = await subjectRepo.getByStreamId(99);
      expect(subjects, isEmpty);
    });
  });

  group('Settings queries', () {
    test('getSetting returns null for missing key', () async {
      final result = await database.getSetting('preferred_stream_id');
      expect(result, isNull);
    });

    test('setSetting and getSetting round-trip', () async {
      await database.setSetting('preferred_stream_id', '1');
      final result = await database.getSetting('preferred_stream_id');
      expect(result, '1');
    });

    test('setSetting overwrites existing value', () async {
      await database.setSetting('preferred_stream_id', '1');
      await database.setSetting('preferred_stream_id', '2');
      final result = await database.getSetting('preferred_stream_id');
      expect(result, '2');
    });
  });

  group('Install identity provider', () {
    test('installIdProvider resolves to a UUID string', () async {
      final installIdRepo = InstallIdentityRepositoryImpl(
        InstallIdentityLocalDataSource(database),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          installIdentityRepositoryProvider.overrideWithValue(installIdRepo),
        ],
      );
      addTearDown(container.dispose);

      final installId = await container.read(installIdProvider.future);
      expect(installId, isNotEmpty);
      // UUID v4 format: 8-4-4-4-12
      expect(
          installId,
          matches(RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          )));
    });

    test('installIdProvider returns the same ID on second read', () async {
      final installIdRepo = InstallIdentityRepositoryImpl(
        InstallIdentityLocalDataSource(database),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          installIdentityRepositoryProvider.overrideWithValue(installIdRepo),
        ],
      );
      addTearDown(container.dispose);

      final id1 = await container.read(installIdProvider.future);
      final id2 = await container.read(installIdProvider.future);
      expect(id1, equals(id2));
    });
  });

  group('Entitlement provider', () {
    late InstallIdentityRepository installIdRepo;
    late EntitlementRepository entitlementRepo;
    late String installId;

    setUp(() async {
      installIdRepo = InstallIdentityRepositoryImpl(
        InstallIdentityLocalDataSource(database),
      );
      entitlementRepo = EntitlementRepositoryImpl(
        EntitlementLocalDataSource(database),
      );
      final identity = await installIdRepo.ensureCreated();
      installId = identity.installId;
    });

    test('activeEntitlementForStreamProvider returns null when no entitlement',
        () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          installIdentityRepositoryProvider.overrideWithValue(installIdRepo),
          entitlementRepositoryProvider.overrideWithValue(entitlementRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        activeEntitlementForStreamProvider(1).future,
      );
      expect(result, isNull);
    });

    test('activeEntitlementForStreamProvider returns Entitlement when active',
        () async {
      // FK requires a stream row
      final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
      await streamRepo.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );

      await entitlementRepo.syncFromServer(installId, [
        Entitlement(
          id: 1,
          installId: installId,
          streamId: 1,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          installIdentityRepositoryProvider.overrideWithValue(installIdRepo),
          entitlementRepositoryProvider.overrideWithValue(entitlementRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        activeEntitlementForStreamProvider(1).future,
      );
      expect(result, isNotNull);
      expect(result!.status, EntitlementStatus.active);
      expect(result.streamId, 1);
    });

    test('activeEntitlementForStreamProvider returns null when revoked',
        () async {
      final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
      await streamRepo.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );

      await entitlementRepo.syncFromServer(installId, [
        Entitlement(
          id: 1,
          installId: installId,
          streamId: 1,
          status: EntitlementStatus.revoked,
          grantedAt: '2026-01-01T00:00:00Z',
          revokedAt: '2026-06-01T00:00:00Z',
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          installIdentityRepositoryProvider.overrideWithValue(installIdRepo),
          entitlementRepositoryProvider.overrideWithValue(entitlementRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        activeEntitlementForStreamProvider(1).future,
      );
      expect(result, isNull);
    });

    test('activeEntitlementForStreamProvider returns null for wrong stream',
        () async {
      final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
      await streamRepo.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );

      await entitlementRepo.syncFromServer(installId, [
        Entitlement(
          id: 1,
          installId: installId,
          streamId: 1,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          installIdentityRepositoryProvider.overrideWithValue(installIdRepo),
          entitlementRepositoryProvider.overrideWithValue(entitlementRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        activeEntitlementForStreamProvider(2).future,
      );
      expect(result, isNull);
    });
  });

  group('SubjectListScreen widget', () {
    Widget buildTestWidget({
      InstallIdentityRepository? installIdRepo,
      EntitlementRepository? entitlementRepo,
    }) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          if (installIdRepo != null)
            installIdentityRepositoryProvider.overrideWithValue(installIdRepo),
          if (entitlementRepo != null)
            entitlementRepositoryProvider.overrideWithValue(entitlementRepo),
        ],
        child: const MaterialApp(home: SubjectListScreen()),
      );
    }

    testWidgets(
        'shows loading skeleton then empty state when no preferred stream',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Preferred stream is null → shows _NoStreamSelected
      expect(find.text('Welcome to EUEE Prep'), findsOneWidget);
      expect(find.text('Select Stream'), findsOneWidget);
    });

    testWidgets('shows subjects when preferred stream and subjects exist',
        (tester) async {
      // Seed data
      final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
      final subjectRepo =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));

      await streamRepo.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );
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

      // Set preferred stream
      await database.setSetting('preferred_stream_id', '1');

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Studying: Natural Science'), findsOneWidget);
    });

    testWidgets('shows empty state when stream is set but no subjects exist',
        (tester) async {
      // Set preferred stream but don't seed any subjects
      await database.setSetting('preferred_stream_id', '1');

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No subjects available'), findsOneWidget);
    });

    testWidgets('shows lock icon when not entitled', (tester) async {
      final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
      final subjectRepo =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));
      final installIdRepo = InstallIdentityRepositoryImpl(
        InstallIdentityLocalDataSource(database),
      );
      final entitlementRepo = EntitlementRepositoryImpl(
        EntitlementLocalDataSource(database),
      );

      await streamRepo.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );
      await subjectRepo.insert(
        const Subject(id: 1, streamId: 1, slug: 'physics', title: 'Physics'),
      );
      await database.setSetting('preferred_stream_id', '1');

      await tester.pumpWidget(buildTestWidget(
        installIdRepo: installIdRepo,
        entitlementRepo: entitlementRepo,
      ));
      await tester.pumpAndSettle();

      // Lock icon present for non-entitled subject
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('shows no lock icon when entitled', (tester) async {
      final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
      final subjectRepo =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));
      final installIdRepo = InstallIdentityRepositoryImpl(
        InstallIdentityLocalDataSource(database),
      );
      final entitlementRepo = EntitlementRepositoryImpl(
        EntitlementLocalDataSource(database),
      );

      await streamRepo.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );
      await subjectRepo.insert(
        const Subject(id: 1, streamId: 1, slug: 'physics', title: 'Physics'),
      );
      await database.setSetting('preferred_stream_id', '1');

      // Grant entitlement
      final identity = await installIdRepo.ensureCreated();
      await entitlementRepo.syncFromServer(identity.installId, [
        Entitlement(
          id: 1,
          installId: identity.installId,
          streamId: 1,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(
        installIdRepo: installIdRepo,
        entitlementRepo: entitlementRepo,
      ));
      await tester.pumpAndSettle();

      // No lock icon when entitled
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      // Subject name is visible
      expect(find.text('Physics'), findsOneWidget);
    });

    testWidgets('shows semantic label with locked when not entitled',
        (tester) async {
      final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
      final subjectRepo =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));
      final installIdRepo = InstallIdentityRepositoryImpl(
        InstallIdentityLocalDataSource(database),
      );
      final entitlementRepo = EntitlementRepositoryImpl(
        EntitlementLocalDataSource(database),
      );

      await streamRepo.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );
      await subjectRepo.insert(
        const Subject(id: 1, streamId: 1, slug: 'physics', title: 'Physics'),
      );
      await database.setSetting('preferred_stream_id', '1');

      await tester.pumpWidget(buildTestWidget(
        installIdRepo: installIdRepo,
        entitlementRepo: entitlementRepo,
      ));
      await tester.pumpAndSettle();

      // Verify semantic label indicates locked state via semantics node
      final semantics = tester.getSemantics(find.text('Physics'));
      expect(semantics.label, contains('locked'));
    });

    testWidgets('tapping locked subject shows payment-related UI',
        (tester) async {
      final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
      final subjectRepo =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));
      final installIdRepo = InstallIdentityRepositoryImpl(
        InstallIdentityLocalDataSource(database),
      );
      final entitlementRepo = EntitlementRepositoryImpl(
        EntitlementLocalDataSource(database),
      );

      await streamRepo.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );
      await subjectRepo.insert(
        const Subject(id: 1, streamId: 1, slug: 'physics', title: 'Physics'),
      );
      await database.setSetting('preferred_stream_id', '1');

      await tester.pumpWidget(buildTestWidget(
        installIdRepo: installIdRepo,
        entitlementRepo: entitlementRepo,
      ));
      await tester.pumpAndSettle();

      // Tap the locked subject
      await tester.tap(find.text('Physics'));
      await tester.pumpAndSettle();

      // Should navigate to PaymentSubmissionFlow — verify step 1 header
      expect(find.textContaining('Unlock'), findsOneWidget);
    });

    testWidgets('tapping entitled subject navigates to detail screen',
        (tester) async {
      final streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
      final subjectRepo =
          SubjectRepositoryImpl(SubjectLocalDataSource(database));
      final installIdRepo = InstallIdentityRepositoryImpl(
        InstallIdentityLocalDataSource(database),
      );
      final entitlementRepo = EntitlementRepositoryImpl(
        EntitlementLocalDataSource(database),
      );

      await streamRepo.insert(
        const StreamModel(id: 1, slug: 'natural_science'),
      );
      await subjectRepo.insert(
        const Subject(id: 1, streamId: 1, slug: 'physics', title: 'Physics'),
      );
      await database.setSetting('preferred_stream_id', '1');

      // Grant entitlement
      final identity = await installIdRepo.ensureCreated();
      await entitlementRepo.syncFromServer(identity.installId, [
        Entitlement(
          id: 1,
          installId: identity.installId,
          streamId: 1,
          status: EntitlementStatus.active,
          grantedAt: '2026-01-01T00:00:00Z',
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(
        installIdRepo: installIdRepo,
        entitlementRepo: entitlementRepo,
      ));
      await tester.pumpAndSettle();

      // Tap the entitled subject
      await tester.tap(find.text('Physics'));
      await tester.pumpAndSettle();

      // Should navigate to SubjectDetailScreen — verify the back button
      // exists (unique to detail screen, not in list)
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
