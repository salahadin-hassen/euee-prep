import '../models/published_paper.dart';

/// Read side of the published-paper catalog plus installed-version lookups.
///
/// The catalog is the only way content reaches students: no manual
/// JSON/ZIP import. Installation state is derived from the existing
/// `content_packs` table — this repository answers the three questions the
/// UI needs: "is it installed?", "which version?", "is there an update?".
abstract interface class PublishedPaperRepository {
  /// Fetches published catalog entries, optionally filtered by [stream],
  /// [subjectSlug], and/or [year].
  Future<List<PublishedPaper>> fetchPapers({
    String? stream,
    String? subjectSlug,
    int? year,
  });

  /// Installed-vs-published state for a single [paper].
  Future<PaperInstallStatus> installStatus(PublishedPaper paper);

  /// Joins [papers] with their install status using a single local read —
  /// the batch shape the Past Papers list consumes.
  Future<List<PaperAvailability>> withInstallStatus(List<PublishedPaper> papers);
}
