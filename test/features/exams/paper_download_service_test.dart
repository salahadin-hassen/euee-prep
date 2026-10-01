import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/core/network/network_client.dart';
import 'package:euee_prep/features/content/data/local_data_sources/content_pack_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/drift_import_transaction.dart';
import 'package:euee_prep/features/content/data/local_data_sources/exam_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/question_local_data_source.dart';
import 'package:euee_prep/features/content/data/repositories/content_pack_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/exam_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/question_repository_impl.dart';
import 'package:euee_prep/features/content/domain/repositories/content_pack_repository.dart';
import 'package:euee_prep/features/content/domain/repositories/exam_repository.dart';
import 'package:euee_prep/features/content/domain/services/content_import_service.dart';
import 'package:euee_prep/features/exams/data/remote_data_sources/published_paper_remote_data_source.dart';
import 'package:euee_prep/features/exams/data/repositories/published_paper_repository_impl.dart';
import 'package:euee_prep/features/exams/domain/models/published_paper.dart';
import 'package:euee_prep/features/exams/domain/services/paper_download_service.dart';
import 'package:euee_prep/features/streams/data/local_data_sources/stream_local_data_source.dart';
import 'package:euee_prep/features/streams/data/repositories/stream_repository_impl.dart';
import 'package:euee_prep/features/subjects/data/local_data_sources/subject_local_data_source.dart';
import 'package:euee_prep/features/subjects/data/repositories/subject_repository_impl.dart';

import 'support/fakes.dart';

void main() {
  late db.AppDatabase database;
  late ContentPackRepository contentPackRepo;
  late ExamRepository examRepo;
  late ContentImportService importService;
  late FakeNetworkClient network;
  late PublishedPaperRepositoryImpl repository;
  late Directory tempRoot;
  late PaperDownloadService service;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    contentPackRepo =
        ContentPackRepositoryImpl(ContentPackLocalDataSource(database));
    examRepo = ExamRepositoryImpl(ExamLocalDataSource(database));
    importService = ContentImportService(
      contentPackRepository: contentPackRepo,
      streamRepository: StreamRepositoryImpl(StreamLocalDataSource(database)),
      subjectRepository: SubjectRepositoryImpl(SubjectLocalDataSource(database)),
      questionRepository:
          QuestionRepositoryImpl(QuestionLocalDataSource(database)),
      examRepository: examRepo,
      transaction: DriftImportTransaction(database),
      currentAppVersion: '1.0.0',
    );
    network = FakeNetworkClient();
    repository = PublishedPaperRepositoryImpl(
      remote: PublishedPaperRemoteDataSource(
        network: network,
        baseUrl: 'https://catalog.test',
      ),
      contentPackRepository: contentPackRepo,
    );
    tempRoot = await Directory.systemTemp.createTemp('paper_download_tests');
    service = PaperDownloadService(
      repository: repository,
      contentPackRepository: contentPackRepo,
      importService: importService,
      network: network,
      temporaryDirectory: () async => tempRoot,
    );
  });

  tearDown(() async {
    await database.close();
    try {
      await tempRoot.delete(recursive: true);
    } catch (_) {
      // Temp cleanup is best-effort.
    }
  });

  group('successful download', () {
    test('downloads, imports through the existing pipeline, and cleans up',
        () async {
      final zip = packZip(fixtureJson());
      network.downloadBytes = zip;
      final paper = paperFromPackJson(fixtureJson(), sizeBytes: zip.length);

      final result = await service.download(paper);

      expect(result.isSuccess, isTrue);
      expect(result.alreadyInstalled, isFalse);
      expect(result.failure, isNull);
      expect(result.pack!.packVersion, '1.0.0');

      // Reached the existing import pipeline: local rows exist.
      final installed = await contentPackRepo.getLatestForPackId(paper.packId);
      expect(installed, isNotNull);
      expect(installed!.packVersion, '1.0.0');
      expect(await examRepo.getAll(), hasLength(1));

      // Downloaded from the catalog's signed URL, and temp files are gone.
      expect(network.downloadRequests.single.toString(), paper.downloadUrl);
      expect(tempRoot.listSync(), isEmpty);
    });

    test('reports monotonic progress that completes at 100%', () async {
      final zip = packZip(fixtureJson());
      network.downloadBytes = zip;
      network.chunkSize = 7;
      final paper = paperFromPackJson(fixtureJson(), sizeBytes: zip.length);
      final events = <PaperDownloadProgress>[];

      final result = await service.download(paper, onProgress: events.add);

      expect(result.isSuccess, isTrue);
      expect(events, hasLength(greaterThan(1)));

      final received = events.map((e) => e.receivedBytes).toList();
      final sorted = List<int>.from(received)..sort();
      expect(received, sorted, reason: 'progress must never go backwards');
      expect(events.first.receivedBytes, greaterThan(0));
      expect(events.last.receivedBytes, zip.length);
      expect(events.last.totalBytes, zip.length);
      expect(events.last.fraction, 1.0);
    });
  });

  group('failure cases', () {
    test('rejects an invalid ZIP', () async {
      network.downloadBytes = utf8.encode('this is not a zip archive');
      final paper = paperFromPackJson(fixtureJson());

      final result = await service.download(paper);

      expect(result.isSuccess, isFalse);
      expect(result.failure, PaperDownloadFailure.invalidZip);
      expect(await contentPackRepo.getAll(), isEmpty);
      expect(tempRoot.listSync(), isEmpty);
    });

    test('rejects a ZIP without content-pack.json', () async {
      network.downloadBytes = zipWithFile('readme.txt', 'hello');
      final paper = paperFromPackJson(fixtureJson());

      final result = await service.download(paper);

      expect(result.failure, PaperDownloadFailure.missingContentPack);
      expect(await contentPackRepo.getAll(), isEmpty);
      expect(tempRoot.listSync(), isEmpty);
    });

    test('rejects malformed JSON inside content-pack.json', () async {
      network.downloadBytes = zipWithFile('content-pack.json', '{"broken":');
      final paper = paperFromPackJson(fixtureJson());

      final result = await service.download(paper);

      expect(result.failure, PaperDownloadFailure.malformedJson);
      expect(await contentPackRepo.getAll(), isEmpty);
    });

    test('rejects a checksum mismatch (existing validator, not re-implemented)',
        () async {
      network.downloadBytes = packZip(corruptChecksumFixture());
      final paper = paperFromPackJson(fixtureJson());

      final result = await service.download(paper);

      expect(result.failure, PaperDownloadFailure.checksumMismatch);
      expect(result.message, contains('checksum'));
      expect(await contentPackRepo.getAll(), isEmpty);
    });

    test('rejects a pack that fails schema validation', () async {
      final invalidSchema = mutateFixture((map) {
        (map['paper'] as Map<String, dynamic>)['question_count'] = 99;
      });
      network.downloadBytes = packZip(invalidSchema);
      final paper = paperFromPackJson(fixtureJson());

      final result = await service.download(paper);

      expect(result.failure, PaperDownloadFailure.importFailed);
      expect(await contentPackRepo.getAll(), isEmpty);
    });

    test('surfaces network failures', () async {
      network.downloadError = NetworkRequestException(
        Uri.parse('https://storage.test/pack.zip'),
        'connection reset',
      );
      final paper = paperFromPackJson(fixtureJson());

      final result = await service.download(paper);

      expect(result.failure, PaperDownloadFailure.network);
      expect(await contentPackRepo.getAll(), isEmpty);
    });

    test('surfaces HTTP failures', () async {
      network.downloadError = HttpStatusException(
        Uri.parse('https://storage.test/pack.zip'),
        503,
      );
      final paper = paperFromPackJson(fixtureJson());

      final result = await service.download(paper);

      expect(result.failure, PaperDownloadFailure.http);
      expect(result.message, contains('503'));
    });

    test('surfaces insufficient storage', () async {
      network.downloadError = const InsufficientStorageException();
      final paper = paperFromPackJson(fixtureJson());

      final result = await service.download(paper);

      expect(result.failure, PaperDownloadFailure.insufficientStorage);
    });

    test('maps ENOSPC file-system errors to insufficient storage', () async {
      network.downloadError = const FileSystemException(
        'No space left on device',
        '/tmp/paper.zip',
        OSError('ENOSPC', 28),
      );
      final paper = paperFromPackJson(fixtureJson());

      final result = await service.download(paper);

      expect(result.failure, PaperDownloadFailure.insufficientStorage);
    });

    test('fails fast when the app version is too old — no download attempted',
        () async {
      final paper = paperFromPackJson(fixtureJson(), minimumAppVersion: '9.9.9');

      final result = await service.download(paper);

      expect(result.failure, PaperDownloadFailure.incompatibleAppVersion);
      expect(network.downloadRequests, isEmpty);
      expect(await contentPackRepo.getAll(), isEmpty);
    });
  });

  group('installed-version behavior', () {
    test('same version already installed is not downloaded again', () async {
      final imported = await importService.import(fixtureJson());
      expect(imported.isSuccess, isTrue);
      final paper = paperFromPackJson(fixtureJson());

      final result = await service.download(paper);

      expect(result.isSuccess, isTrue);
      expect(result.alreadyInstalled, isTrue);
      expect(network.downloadRequests, isEmpty);
      expect(tempRoot.listSync(), isEmpty);
      expect(await contentPackRepo.getAll(), hasLength(1));
    });

    test('newer published version is downloaded and becomes active', () async {
      await importService.import(fixtureJson()); // installs 1.0.0
      final v110 = reversionedFixture('1.1.0');
      network.downloadBytes = packZip(v110);
      final paper = paperFromPackJson(v110);

      final result = await service.download(paper);

      expect(result.isSuccess, isTrue);
      expect(result.alreadyInstalled, isFalse);
      expect(network.downloadRequests, hasLength(1));

      final latest = await contentPackRepo.getLatestForPackId(paper.packId);
      expect(latest!.packVersion, '1.1.0');
      // The previous version remains installed (insert-only, coexistence).
      expect(await contentPackRepo.getAll(), hasLength(2));
    });

    test('a failed update preserves the previously installed version',
        () async {
      final imported = await importService.import(fixtureJson());
      expect(imported.isSuccess, isTrue);
      final examsBefore = await examRepo.getAll();
      final questionIdsBefore = examsBefore.single.questionIds;

      // Catalog says 1.1.0, but the artifact is corrupt.
      network.downloadBytes = packZip(corruptChecksumFixture());
      final paper = paperFromPackJson(fixtureJson(), packVersion: '1.1.0');

      final result = await service.download(paper);

      expect(result.isSuccess, isFalse);
      expect(result.failure, PaperDownloadFailure.checksumMismatch);

      // Previously installed version still active, no duplicate exam rows.
      final latest = await contentPackRepo.getLatestForPackId(paper.packId);
      expect(latest!.packVersion, '1.0.0');
      final examsAfter = await examRepo.getAll();
      expect(examsAfter, hasLength(1));
      expect(examsAfter.single.questionIds, questionIdsBefore);

      // Still awaiting the update.
      final status = await repository.installStatus(paper);
      expect(status.state, PaperInstallState.updateAvailable);
      expect(tempRoot.listSync(), isEmpty);
    });
  });
}
