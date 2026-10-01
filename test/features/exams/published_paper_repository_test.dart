import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/network/network_client.dart';
import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/features/content/data/local_data_sources/content_pack_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/drift_import_transaction.dart';
import 'package:euee_prep/features/content/data/local_data_sources/exam_local_data_source.dart';
import 'package:euee_prep/features/content/data/local_data_sources/question_local_data_source.dart';
import 'package:euee_prep/features/content/data/repositories/content_pack_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/exam_repository_impl.dart';
import 'package:euee_prep/features/content/data/repositories/question_repository_impl.dart';
import 'package:euee_prep/features/content/domain/repositories/content_pack_repository.dart';
import 'package:euee_prep/features/content/domain/services/content_import_service.dart';
import 'package:euee_prep/features/exams/data/remote_data_sources/published_paper_remote_data_source.dart';
import 'package:euee_prep/features/exams/data/repositories/published_paper_repository_impl.dart';
import 'package:euee_prep/features/exams/domain/models/published_paper.dart';
import 'package:euee_prep/features/streams/data/local_data_sources/stream_local_data_source.dart';
import 'package:euee_prep/features/streams/data/repositories/stream_repository_impl.dart';
import 'package:euee_prep/features/subjects/data/local_data_sources/subject_local_data_source.dart';
import 'package:euee_prep/features/subjects/data/repositories/subject_repository_impl.dart';

import 'support/fakes.dart';

void main() {
  late db.AppDatabase database;
  late ContentPackRepository contentPackRepo;
  late ContentImportService importService;
  late FakeNetworkClient network;
  late PublishedPaperRepositoryImpl repository;

  final physicsPaper = paperFromPackJson(fixtureJson());

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    contentPackRepo =
        ContentPackRepositoryImpl(ContentPackLocalDataSource(database));
    importService = ContentImportService(
      contentPackRepository: contentPackRepo,
      streamRepository: StreamRepositoryImpl(StreamLocalDataSource(database)),
      subjectRepository: SubjectRepositoryImpl(SubjectLocalDataSource(database)),
      questionRepository:
          QuestionRepositoryImpl(QuestionLocalDataSource(database)),
      examRepository: ExamRepositoryImpl(ExamLocalDataSource(database)),
      transaction: DriftImportTransaction(database),
    );
    network = FakeNetworkClient();
    repository = PublishedPaperRepositoryImpl(
      remote: PublishedPaperRemoteDataSource(
        network: network,
        baseUrl: 'https://catalog.test',
      ),
      contentPackRepository: contentPackRepo,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('fetchPapers', () {
    test('parses catalog metadata from the endpoint envelope', () async {
      network.catalogBody = catalogBody([physicsPaper]);

      final papers = await repository.fetchPapers();

      expect(papers, hasLength(1));
      expect(papers.single.packId, 'physics-2015-natural-science');
      expect(papers.single.packVersion, '1.0.0');
      expect(papers.single.questionCount, 3);
      expect(papers.single.downloadUrl, isNotEmpty);
    });

    test('sends stream, subject, and year filters as query parameters',
        () async {
      network.catalogBody = catalogBody([physicsPaper]);

      await repository.fetchPapers(
        stream: 'natural_science',
        subjectSlug: 'physics',
        year: 2015,
      );

      final uri = network.stringRequests.single;
      expect(uri.path, '/api/published-papers');
      expect(uri.queryParameters, {
        'stream': 'natural_science',
        'subject': 'physics',
        'year': '2015',
      });
    });

    test('omits absent filters from the query string', () async {
      network.catalogBody = catalogBody(const []);

      await repository.fetchPapers(stream: 'social_science');

      expect(network.stringRequests.single.queryParameters, {
        'stream': 'social_science',
      });
    });

    test('propagates network failures from the catalog fetch', () async {
      network = FakeNetworkClient(); // no catalog body scripted â†’ failure
      repository = PublishedPaperRepositoryImpl(
        remote: PublishedPaperRemoteDataSource(
          network: network,
          baseUrl: 'https://catalog.test',
        ),
        contentPackRepository: contentPackRepo,
      );

      await expectLater(
        repository.fetchPapers(),
        throwsA(isA<NetworkRequestException>()),
      );
    });

    test('rejects a malformed catalog payload', () async {
      network.catalogBody = 'not-json';

      await expectLater(repository.fetchPapers(), throwsA(isA<FormatException>()));
    });

    test('rejects an envelope without papers', () async {
      network.catalogBody = '{"items":[]}';

      await expectLater(repository.fetchPapers(), throwsA(isA<FormatException>()));
    });

    test('fails clearly when the API base URL is not configured', () async {
      final unconfigured = PublishedPaperRepositoryImpl(
        remote: PublishedPaperRemoteDataSource(
          network: network,
          baseUrl: '',
        ),
        contentPackRepository: contentPackRepo,
      );

      await expectLater(
        unconfigured.fetchPapers(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('install status', () {
    test('is available when no pack is installed', () async {
      final status = await repository.installStatus(physicsPaper);

      expect(status.state, PaperInstallState.available);
      expect(status.installedVersion, isNull);
    });

    test('becomes installed after the existing import pipeline runs', () async {
      final import = await importService.import(fixtureJson());
      expect(import.isSuccess, isTrue);

      final status = await repository.installStatus(physicsPaper);

      expect(status.state, PaperInstallState.installed);
      expect(status.installedVersion, '1.0.0');
    });

    test('reports updateAvailable when the catalog is newer than installed',
        () async {
      await importService.import(fixtureJson());
      final newer = paperFromPackJson(fixtureJson(), packVersion: '1.1.0');

      final status = await repository.installStatus(newer);

      expect(status.state, PaperInstallState.updateAvailable);
      expect(status.installedVersion, '1.0.0');
      expect(status.publishedVersion, '1.1.0');
    });

    test('withInstallStatus joins a whole catalog in one local read', () async {
      await importService.import(fixtureJson());
      final newerPhysics = paperFromPackJson(fixtureJson(), packVersion: '1.1.0');
      const biology = PublishedPaper(
        packId: 'biology-2018-natural_science',
        subjectSlug: 'biology',
        subjectTitle: 'Biology',
        stream: 'natural_science',
        year: 2018,
        title: 'EUEE Biology 2018',
        questionCount: 4,
        packVersion: '1.0.0',
        sizeBytes: 2048,
        storagePath: 'biology-2018-natural_science/1.0.0.zip',
        publishedAt: '2026-10-01T00:00:00.000Z',
        minimumAppVersion: '1.0.0',
        updatedAt: '2026-10-01T00:00:00.000Z',
        downloadUrl: 'https://storage.test/biology.zip',
      );

      final availability = await repository
          .withInstallStatus([newerPhysics, biology]);

      expect(availability, hasLength(2));
      expect(availability[0].paper.packVersion, '1.1.0');
      expect(availability[0].state, PaperInstallState.updateAvailable);
      expect(availability[1].paper.packId, 'biology-2018-natural_science');
      expect(availability[1].state, PaperInstallState.available);
    });

    test('withInstallStatus returns empty for an empty catalog', () async {
      expect(await repository.withInstallStatus(const []), isEmpty);
    });
  });
}
