import '../../../../core/utilities/semver.dart';
import '../../../content/domain/repositories/content_pack_repository.dart';
import '../../domain/models/published_paper.dart';
import '../../domain/repositories/published_paper_repository.dart';
import '../remote_data_sources/published_paper_remote_data_source.dart';

class PublishedPaperRepositoryImpl implements PublishedPaperRepository {
  PublishedPaperRepositoryImpl({
    required PublishedPaperRemoteDataSource remote,
    required ContentPackRepository contentPackRepository,
  })  : _remote = remote,
        _contentPackRepository = contentPackRepository;

  final PublishedPaperRemoteDataSource _remote;
  final ContentPackRepository _contentPackRepository;

  @override
  Future<List<PublishedPaper>> fetchPapers({
    String? stream,
    String? subjectSlug,
    int? year,
  }) {
    return _remote.fetch(stream: stream, subjectSlug: subjectSlug, year: year);
  }

  @override
  Future<PaperInstallStatus> installStatus(PublishedPaper paper) async {
    final installed = await _contentPackRepository.getLatestForPackId(
      paper.packId,
    );
    return PaperInstallStatus.compute(
      publishedVersion: paper.packVersion,
      installedVersion: installed?.packVersion,
    );
  }

  @override
  Future<List<PaperAvailability>> withInstallStatus(
    List<PublishedPaper> papers,
  ) async {
    if (papers.isEmpty) return const [];

    final installedVersionByPackId = await _latestInstalledVersions();
    return [
      for (final paper in papers)
        PaperAvailability(
          paper: paper,
          status: PaperInstallStatus.compute(
            publishedVersion: paper.packVersion,
            installedVersion: installedVersionByPackId[paper.packId],
          ),
        ),
    ];
  }

  /// One local read that answers "which version is installed?" for every
  /// pack id — newest installed version per paper, by the shared semver
  /// rules.
  Future<Map<String, String>> _latestInstalledVersions() async {
    final latest = <String, String>{};
    for (final pack in await _contentPackRepository.getAll()) {
      final packId = _packIdOf(pack.id);
      if (packId == null) continue;
      final current = latest[packId];
      if (current == null || compareSemVer(pack.packVersion, current) > 0) {
        latest[packId] = pack.packVersion;
      }
    }
    return latest;
  }

  /// Splits a local `content_packs.id` (`{pack_id}#{pack_version}`) back
  /// into its file-level pack id.
  String? _packIdOf(String contentPackId) {
    final separator = contentPackId.lastIndexOf('#');
    if (separator <= 0) return null;
    return contentPackId.substring(0, separator);
  }
}
