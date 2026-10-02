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
import 'package:euee_prep/features/content/domain/models/content_pack.dart';
import 'package:euee_prep/features/content/domain/models/exam.dart';
import 'package:euee_prep/features/content/domain/models/question.dart';
import 'package:euee_prep/features/exams/data/remote_data_sources/published_paper_remote_data_source.dart';
import 'package:euee_prep/features/exams/domain/models/published_paper.dart';
import 'package:euee_prep/features/exams/domain/services/paper_download_service.dart';
import 'package:euee_prep/features/streams/data/local_data_sources/stream_local_data_source.dart';
import 'package:euee_prep/features/streams/data/repositories/stream_repository_impl.dart';
import 'package:euee_prep/features/streams/domain/models/stream_model.dart';
import 'package:euee_prep/features/subjects/data/local_data_sources/subject_local_data_source.dart';
import 'package:euee_prep/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:euee_prep/features/subjects/domain/models/subject.dart';
import 'package:euee_prep/features/subjects/presentation/subject_detail_screen.dart';

/// Catalog responses without a network; install status still comes from
/// the real repository reading the seeded `content_packs` rows.
class _FakeRemote implements PublishedPaperRemoteDataSource {
  _FakeRemote(this.papers, {this.fail = false});

  final List<PublishedPaper> papers;
  final bool fail;

  @override
  Future<List<PublishedPaper>> fetch({
    String? stream,
    String? subjectSlug,
    int? year,
  }) async {
    if (fail) throw Exception('catalog unreachable');
    return papers
        .where((paper) =>
            (stream == null || paper.stream == stream) &&
            (subjectSlug == null || paper.subjectSlug == subjectSlug) &&
            (year == null || paper.year == year))
        .toList();
  }
}

class _FakeDownloadService implements PaperDownloadService {
  _FakeDownloadService({this.fail = false});

  final bool fail;
  bool called = false;
  PublishedPaper? lastPaper;

  @override
  Future<PaperDownloadResult> download(
    PublishedPaper paper, {
    void Function(PaperDownloadProgress progress)? onProgress,
  }) async {
    called = true;
    lastPaper = paper;
    if (fail) {
      return PaperDownloadResult.failed(
        PaperDownloadFailure.network,
        'Connection failed',
      );
    }
    return PaperDownloadResult.installed(
      ContentPack(
        id: paper.packVersionId,
        packKey: paper.packId,
        subjectId: 1,
        packVersion: paper.packVersion,
        schemaVersion: '3.0.0',
        generatedAt: '2026-01-01T00:00:00Z',
        checksum: 'deadbeef',
        minimumAppVersion: '0.0.0',
        importedAt: '2026-01-01T00:00:00Z',
      ),
      alreadyInstalled: false,
    );
  }
}

PublishedPaper _paper({
  required String packId,
  required String packVersion,
}) =>
    PublishedPaper(
      packId: packId,
      subjectSlug: 'biology',
      subjectTitle: 'Biology',
      stream: 'natural_science',
      year: 2018,
      title: 'Biology 2018',
      questionCount: 50,
      packVersion: packVersion,
      sizeBytes: 1024,
      storagePath: 'biology-2018.zip',
      publishedAt: '2026-01-01T00:00:00Z',
      minimumAppVersion: '0.0.0',
      updatedAt: '2026-01-01T00:00:00Z',
      downloadUrl: 'https://example.com/biology-2018.zip',
    );

void main() {
  late db.AppDatabase database;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());

    await StreamRepositoryImpl(StreamLocalDataSource(database)).insert(
      const StreamModel(id: 1, slug: 'natural_science'),
    );
    await SubjectRepositoryImpl(SubjectLocalDataSource(database)).insert(
      const Subject(id: 1, streamId: 1, slug: 'biology', title: 'Biology'),
    );
    await database.setSetting('preferred_stream_id', '1');
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> seedExam({required String sourcePackId}) async {
    // Exams reference a content_packs row (FK) — mirror the real
    // `{pack_id}#{pack_version}` local id written by the importer.
    await database.into(database.contentPacks).insert(
          db.ContentPacksCompanion.insert(
            id: sourcePackId,
            packKey: 'natural_science-biology',
            subjectId: 1,
            packVersion: sourcePackId.split('#').last,
            schemaVersion: '3.0.0',
            generatedAt: '2026-01-01T00:00:00Z',
            checksum: 'sha256:one',
            minimumAppVersion: '0.0.0',
            importedAt: '2026-01-01T00:00:00Z',
          ),
        );

    final questionRepo =
        QuestionRepositoryImpl(QuestionLocalDataSource(database));
    for (var i = 1; i <= 3; i++) {
      await questionRepo.insert(
        Question(
          id: i,
          sourcePackId: sourcePackId,
          packLocalId: 'q$i',
          prompt: 'Question $i',
          choicesJson: '["a", "b", "c", "d"]',
          correctChoiceIndex: 0,
          topicIds: const [],
        ),
      );
    }

    final examRepo = ExamRepositoryImpl(ExamLocalDataSource(database));
    await examRepo.insert(
      Exam(
        id: 1,
        sourcePackId: sourcePackId,
        packLocalId: 'paper-1',
        subjectId: 1,
        examYearEc: 2018,
        questionIds: const [1, 2, 3],
      ),
    );
  }

  Widget buildDetail({
    required _FakeRemote remote,
    required _FakeDownloadService service,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        publishedPaperRemoteDataSourceProvider.overrideWithValue(remote),
        paperDownloadServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(
        home: SubjectDetailScreen(
          subjectId: 1,
          subjectName: 'Biology',
          subjectSlug: 'biology',
          streamId: 1,
        ),
      ),
    );
  }

  testWidgets('shows Download for a published paper that is not installed',
      (tester) async {
    final remote = _FakeRemote([
      _paper(packId: 'bio-2018', packVersion: '1.0.0'),
    ]);

    await tester.pumpWidget(buildDetail(
      remote: remote,
      service: _FakeDownloadService(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Biology 2018'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('No papers available'), findsNothing);
  });

  testWidgets('tapping Download drives the download pipeline',
      (tester) async {
    final remote = _FakeRemote([
      _paper(packId: 'bio-2018', packVersion: '1.0.0'),
    ]);
    final service = _FakeDownloadService();

    await tester.pumpWidget(buildDetail(remote: remote, service: service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(service.called, isTrue);
    expect(service.lastPaper?.packId, 'bio-2018');
  });

  testWidgets('an installed paper with a newer published version shows Update',
      (tester) async {
    await seedExam(sourcePackId: 'bio-2018#1.0.0');
    final remote = _FakeRemote([
      _paper(packId: 'bio-2018', packVersion: '2.0.0'),
    ]);

    await tester.pumpWidget(buildDetail(
      remote: remote,
      service: _FakeDownloadService(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Download'), findsNothing);
    expect(find.text('Open'), findsNothing);
  });

  testWidgets('an installed paper at the published version shows Open',
      (tester) async {
    await seedExam(sourcePackId: 'bio-2018#1.0.0');
    final remote = _FakeRemote([
      _paper(packId: 'bio-2018', packVersion: '1.0.0'),
    ]);

    await tester.pumpWidget(buildDetail(
      remote: remote,
      service: _FakeDownloadService(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Download'), findsNothing);
    expect(find.text('Update'), findsNothing);
  });

  testWidgets('a failed download surfaces Retry without losing the row',
      (tester) async {
    final remote = _FakeRemote([
      _paper(packId: 'bio-2018', packVersion: '1.0.0'),
    ]);

    await tester.pumpWidget(buildDetail(
      remote: remote,
      service: _FakeDownloadService(fail: true),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Biology 2018'), findsOneWidget);
    expect(find.text('No papers available'), findsNothing);
  });

  testWidgets('falls back to local papers when the catalog is unreachable',
      (tester) async {
    await seedExam(sourcePackId: 'bio-2018#1.0.0');
    final remote = _FakeRemote(const [], fail: true);

    await tester.pumpWidget(buildDetail(
      remote: remote,
      service: _FakeDownloadService(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('No papers available'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
