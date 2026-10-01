import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:euee_prep/core/database/app_database.dart' as db;
import 'package:euee_prep/core/providers.dart';
import 'package:euee_prep/features/exams/data/remote_data_sources/published_paper_remote_data_source.dart';
import 'package:euee_prep/features/exams/domain/models/published_paper.dart';
import 'package:euee_prep/features/exams/domain/services/paper_download_service.dart';
import 'package:euee_prep/features/exams/presentation/paper_download_controller.dart';

import 'support/fakes.dart';

void main() {
  test(
      'a downloaded v3 pack reaches ContentImportService and becomes visible '
      'through the existing learner repositories', () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => database.close());

    final zip = packZip(fixtureJson());
    final paper = paperFromPackJson(fixtureJson(), sizeBytes: zip.length);
    final network = FakeNetworkClient(
      catalogBody: catalogBody([paper]),
      downloadBytes: zip,
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        networkClientProvider.overrideWithValue(network),
        temporaryDirectoryProvider.overrideWithValue(() async => Directory.systemTemp),
        publishedPaperRemoteDataSourceProvider.overrideWithValue(
          PublishedPaperRemoteDataSource(
            network: network,
            baseUrl: 'https://catalog.test',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    const query = PublishedPaperQuery(
      stream: 'natural_science',
      subjectSlug: 'physics',
    );

    // 1. Catalog entry is available (not yet installed).
    final before = await container.read(papersWithStatusProvider(query).future);
    expect(before, hasLength(1));
    expect(before.single.state, PaperInstallState.available);
    expect(before.single.paper.packId, 'physics-2015-natural-science');

    // 2. Student selects the paper → download runs through the controller.
    final controller =
        container.read(paperDownloadControllerProvider.notifier);
    final result = await controller.download(before.single.paper);

    expect(result.isSuccess, isTrue);
    expect(result.pack, isNotNull);

    // 3. The controller surfaces the installed state to the UI layer.
    final downloadState = container.read(paperDownloadControllerProvider);
    expect(downloadState.phase, PaperDownloadPhase.installed);
    expect(downloadState.installedVersion, '1.0.0');

    // 4. The pack exists in the existing content repository (what
    //    ContentImportService writes).
    final pack = await container
        .read(contentPackRepositoryProvider)
        .getLatestForPackId(paper.packId);
    expect(pack, isNotNull);
    expect(pack!.packVersion, '1.0.0');

    // 5. The paper is visible through the existing learner path
    //    (Subject Detail → Past Papers reads examsBySubjectProvider).
    final subjectId = pack.subjectId;
    final exams =
        await container.read(examRepositoryProvider).getBySubjectId(subjectId);
    expect(exams, hasLength(1));
    expect(exams.single.examYearEc, 2015);

    final learnerPapers =
        await container.read(examsBySubjectProvider(subjectId).future);
    expect(learnerPapers, hasLength(1));

    // 6. After invalidation the catalog reports the paper as installed.
    final after = await container.read(papersWithStatusProvider(query).future);
    expect(after.single.state, PaperInstallState.installed);
    expect(after.single.status.installedVersion, '1.0.0');
  });

  test('a failed download surfaces a failed state and installs nothing',
      () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => database.close());

    final paper = paperFromPackJson(fixtureJson());
    final network = FakeNetworkClient(
      catalogBody: catalogBody([paper]),
      downloadBytes: <int>[1, 2, 3, 4], // not a ZIP
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        networkClientProvider.overrideWithValue(network),
        temporaryDirectoryProvider.overrideWithValue(() async => Directory.systemTemp),
        publishedPaperRemoteDataSourceProvider.overrideWithValue(
          PublishedPaperRemoteDataSource(
            network: network,
            baseUrl: 'https://catalog.test',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    const query = PublishedPaperQuery(
      stream: 'natural_science',
      subjectSlug: 'physics',
    );
    final before = await container.read(papersWithStatusProvider(query).future);

    final controller =
        container.read(paperDownloadControllerProvider.notifier);
    final result = await controller.download(before.single.paper);

    expect(result.isSuccess, isFalse);
    expect(result.failure, PaperDownloadFailure.invalidZip);

    final state = container.read(paperDownloadControllerProvider);
    expect(state.phase, PaperDownloadPhase.failed);
    expect(state.failure, PaperDownloadFailure.invalidZip);
    expect(state.message, isNotEmpty);

    // Nothing was installed; the catalog still offers it as available.
    expect(await container.read(contentPackRepositoryProvider).getAll(), isEmpty);
    final after = await container.read(papersWithStatusProvider(query).future);
    expect(after.single.state, PaperInstallState.available);
  });
}
