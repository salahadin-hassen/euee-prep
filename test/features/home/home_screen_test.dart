import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/core/providers.dart';
import 'package:euee_prep/features/content/data/local_data_sources/exam_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/question_local_data_source.dart';
import 'package:euee_prep/features/content/data/repositories/exam_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/question_repository_impl.dart';
import 'package:euee_prep/features/content/domain/models/exam.dart';
import 'package:euee_prep/features/content/domain/models/question.dart';
import 'package:euee_prep/features/entitlements/data/local_data_sources/entitlement_local_data_source.dart';
import 'package:euee_prep/features/entitlements/data/local_data_sources/install_identity_local_data_source.dart';
import 'package:euee_prep/features/entitlements/data/repositories/entitlement_repository_impl.dart';
import 'package:euee_prep/features/entitlements/data/repositories/install_identity_repository_impl.dart';
import 'package:euee_prep/features/entitlements/domain/models/entitlement.dart';
import 'package:euee_prep/features/entitlements/domain/repositories/entitlement_repository.dart';
import 'package:euee_prep/features/entitlements/domain/repositories/install_identity_repository.dart';
import 'package:euee_prep/features/home/presentation/home_screen.dart';
import 'package:euee_prep/features/progress/data/local_data_sources/attempt_local_data_source.dart';
import 'package:euee_prep/features/progress/data/repositories/attempt_repository_impl.dart';
import 'package:euee_prep/features/progress/domain/models/attempt.dart';
import 'package:euee_prep/features/streams/data/local_data_sources/stream_local_data_source.dart';
import 'package:euee_prep/features/streams/data/repositories/stream_repository_impl.dart';
import 'package:euee_prep/features/streams/domain/models/stream_model.dart';
import 'package:euee_prep/features/subjects/data/local_data_sources/subject_local_data_source.dart';
import 'package:euee_prep/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:euee_prep/features/subjects/domain/models/subject.dart';

void main() {
  late db.AppDatabase database;
  late StreamRepositoryImpl streamRepo;
  late SubjectRepositoryImpl subjectRepo;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    streamRepo = StreamRepositoryImpl(StreamLocalDataSource(database));
    subjectRepo = SubjectRepositoryImpl(SubjectLocalDataSource(database));

    await streamRepo.insert(
      const StreamModel(id: 1, slug: 'natural_science'),
    );
    await subjectRepo.insert(
      const Subject(id: 1, streamId: 1, slug: 'biology', title: 'Biology'),
    );
    await subjectRepo.insert(
      const Subject(id: 2, streamId: 1, slug: 'chemistry', title: 'Chemistry'),
    );
    await database.setSetting('preferred_stream_id', '1');
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildHome({
    required db.AppDatabase withDatabase,
    InstallIdentityRepository? installIdRepo,
    EntitlementRepository? entitlementRepo,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(withDatabase),
        if (installIdRepo != null)
          installIdentityRepositoryProvider.overrideWithValue(installIdRepo),
        if (entitlementRepo != null)
          entitlementRepositoryProvider.overrideWithValue(entitlementRepo),
      ],
      child: MaterialApp(
        home: HomeScreen(onViewAll: () {}),
      ),
    );
  }

  testWidgets('shows the welcome state when no Preferred Stream is set',
      (tester) async {
    await database.setSetting('preferred_stream_id', '');

    await tester.pumpWidget(buildHome(withDatabase: database));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to EUEE Prep'), findsOneWidget);
    expect(find.text('Select Stream'), findsOneWidget);
  });

  testWidgets('shows the empty state when the stream has no subjects',
      (tester) async {
    await database.delete(database.subjects).go();

    await tester.pumpWidget(buildHome(withDatabase: database));
    await tester.pumpAndSettle();

    expect(find.text('No subjects available'), findsOneWidget);
  });

  testWidgets('renders real dashboard numbers, preview and offline row',
      (tester) async {
    // Tall surface so the whole dashboard renders without scrolling.
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _seedPaperAndAttempts(database);

    await tester.pumpWidget(buildHome(withDatabase: database));
    await tester.pumpAndSettle();

    expect(find.text('CONTINUE STUDYING'), findsOneWidget);
    // Once on the Continue card, once in the subject preview.
    expect(find.text('Biology'), findsNWidgets(2));
    expect(find.text('2017 E.C. paper'), findsOneWidget);
    expect(find.text('Next: question 3 of 4'), findsOneWidget);
    // Shown on the Continue card and on the Biology preview row.
    expect(find.text('50%'), findsNWidgets(2));

    expect(find.text('Questions answered'), findsOneWidget);
    expect(find.text('Papers started'), findsOneWidget);
    expect(find.text('Active subjects'), findsOneWidget);

    expect(find.text('YOUR SUBJECTS'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
    expect(find.text('2 of 4 questions'), findsOneWidget);

    expect(find.text('1 paper is ready offline'), findsOneWidget);
    expect(find.text('Unlock all subjects'), findsOneWidget);
    expect(find.text('Offline video on how to unlock all'), findsOneWidget);
  });

  testWidgets('renders without layout overflow on a small phone screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _seedPaperAndAttempts(database);

    await tester.pumpWidget(buildHome(withDatabase: database));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('CONTINUE STUDYING'), findsOneWidget);

    // Scroll to the bottom of the dashboard to surface any overflow there.
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the unlock bar once the stream is entitled',
      (tester) async {
    final installIdRepo = InstallIdentityRepositoryImpl(
      InstallIdentityLocalDataSource(database),
    );
    final entitlementRepo = EntitlementRepositoryImpl(
      EntitlementLocalDataSource(database),
    );
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

    await tester.pumpWidget(
      buildHome(
        withDatabase: database,
        installIdRepo: installIdRepo,
        entitlementRepo: entitlementRepo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unlock all subjects'), findsNothing);
    expect(find.text('Offline video on how to unlock all'), findsNothing);
    expect(find.text('Biology'), findsOneWidget);
  });
}

/// One Biology paper with four questions, the first two answered.
Future<void> _seedPaperAndAttempts(db.AppDatabase database) async {
  final questionRepo =
      QuestionRepositoryImpl(QuestionLocalDataSource(database));
  final examRepo = ExamRepositoryImpl(ExamLocalDataSource(database));
  final attemptRepo =
      AttemptRepositoryImpl(AttemptLocalDataSource(database));

  // Questions and exams both reference a content pack row.
  await database.into(database.contentPacks).insert(
        db.ContentPacksCompanion.insert(
          id: 'pack-1',
          packKey: 'natural_science-biology',
          subjectId: 1,
          packVersion: '1.0.0',
          schemaVersion: '2',
          generatedAt: '2025-12-01T00:00:00Z',
          checksum: 'sha256:one',
          minimumAppVersion: '0.1.0',
          importedAt: '2026-01-01T00:00:00Z',
        ),
      );

  for (var i = 1; i <= 4; i++) {
    await questionRepo.insert(
      Question(
        id: i,
        sourcePackId: 'pack-1',
        packLocalId: 'q$i',
        prompt: 'Question $i',
        choicesJson: '["a", "b", "c", "d"]',
        correctChoiceIndex: 0,
        topicIds: const [],
      ),
    );
  }

  await examRepo.insert(
    Exam(
      id: 1,
      sourcePackId: 'pack-1',
      packLocalId: 'paper-2017',
      subjectId: 1,
      examYearEc: 2017,
      questionIds: const [1, 2, 3, 4],
    ),
  );

  for (final questionId in [1, 2]) {
    await attemptRepo.insert(
      Attempt(
        id: 0,
        questionId: questionId,
        selectedChoiceIndex: 0,
        isCorrect: true,
        attemptedAt: '2026-01-0${questionId}T00:00:00Z',
        mode: 'practice',
        subjectId: 1,
        examId: 1,
      ),
    );
  }
}
