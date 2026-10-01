import '../../../../core/utilities/semver.dart';

/// One published paper version from the backend catalog
/// (`GET /api/published-papers`).
///
/// Identity of a catalog entry is `(packId, packVersion)` — the same pair the
/// local `content_packs` table uses (`{pack_id}#{pack_version}`), which is how
/// installed state is derived without a second install-tracking table.
class PublishedPaper {
  const PublishedPaper({
    required this.packId,
    required this.subjectSlug,
    required this.subjectTitle,
    required this.stream,
    required this.year,
    required this.title,
    required this.questionCount,
    required this.packVersion,
    required this.sizeBytes,
    required this.storagePath,
    required this.publishedAt,
    required this.minimumAppVersion,
    required this.updatedAt,
    required this.downloadUrl,
    this.id,
  });

  /// Parses one catalog entry, rejecting missing or mistyped fields with a
  /// [FormatException] (the catalog is a hard contract, not best-effort).
  factory PublishedPaper.fromJson(Map<String, dynamic> json) {
    return PublishedPaper(
      id: _stringOrNull(json, 'id'),
      packId: _string(json, 'pack_id'),
      subjectSlug: _string(json, 'subject_slug'),
      subjectTitle: _string(json, 'subject_title'),
      stream: _string(json, 'stream'),
      year: _int(json, 'year'),
      title: _string(json, 'title'),
      questionCount: _int(json, 'question_count'),
      packVersion: _string(json, 'pack_version'),
      sizeBytes: _int(json, 'size_bytes'),
      storagePath: _string(json, 'storage_path'),
      publishedAt: _string(json, 'published_at'),
      minimumAppVersion: _string(json, 'minimum_app_version'),
      updatedAt: _string(json, 'updated_at'),
      downloadUrl: _string(json, 'download_url'),
    );
  }

  /// Server-side row id (nullable — not used for identity).
  final String? id;

  /// File-level pack id, e.g. `biology-2018-natural_science`.
  final String packId;

  final String subjectSlug;
  final String subjectTitle;
  final String stream;
  final int year;
  final String title;
  final int questionCount;

  /// Published pack version, e.g. `1.0.0`.
  final String packVersion;

  /// Expected ZIP size in bytes; used as the progress total when the
  /// download response has no content length.
  final int sizeBytes;

  final String storagePath;
  final String publishedAt;
  final String minimumAppVersion;
  final String updatedAt;

  /// Short-lived signed URL for the ZIP in Storage.
  final String downloadUrl;

  /// Matches the local `content_packs.id` format: `{pack_id}#{pack_version}`.
  String get packVersionId => '$packId#$packVersion';

  /// Inverse of [fromJson] — the exact JSON shape the catalog endpoint
  /// returns.
  Map<String, dynamic> toJson() => {
        'id': id,
        'pack_id': packId,
        'subject_slug': subjectSlug,
        'subject_title': subjectTitle,
        'stream': stream,
        'year': year,
        'title': title,
        'question_count': questionCount,
        'pack_version': packVersion,
        'size_bytes': sizeBytes,
        'storage_path': storagePath,
        'published_at': publishedAt,
        'minimum_app_version': minimumAppVersion,
        'updated_at': updatedAt,
        'download_url': downloadUrl,
      };

  @override
  bool operator ==(Object other) =>
      other is PublishedPaper && other.packVersionId == packVersionId;

  @override
  int get hashCode => packVersionId.hashCode;

  @override
  String toString() => 'PublishedPaper($packVersionId)';
}

/// What the device can say about one published paper.
enum PaperInstallState {
  /// No version of this paper is installed.
  available,

  /// The published version (or a newer one) is installed.
  installed,

  /// An older version is installed; a newer published version exists.
  updateAvailable,
}

/// Installed-vs-published comparison for one paper.
class PaperInstallStatus {
  const PaperInstallStatus._({
    required this.publishedVersion,
    required this.installedVersion,
    required this.state,
  });

  /// Derives the state by comparing [installedVersion] (the newest locally
  /// installed version, or `null`) against [publishedVersion] using the
  /// shared semver rules.
  factory PaperInstallStatus.compute({
    required String publishedVersion,
    String? installedVersion,
  }) {
    final PaperInstallState state;
    if (installedVersion == null) {
      state = PaperInstallState.available;
    } else if (compareSemVer(installedVersion, publishedVersion) >= 0) {
      state = PaperInstallState.installed;
    } else {
      state = PaperInstallState.updateAvailable;
    }
    return PaperInstallStatus._(
      publishedVersion: publishedVersion,
      installedVersion: installedVersion,
      state: state,
    );
  }

  final String publishedVersion;
  final String? installedVersion;
  final PaperInstallState state;
}

/// A catalog paper joined with its local install status — the unit the
/// Past Papers UI renders (Available / Installed / Update available).
class PaperAvailability {
  const PaperAvailability({required this.paper, required this.status});

  final PublishedPaper paper;
  final PaperInstallStatus status;

  PaperInstallState get state => status.state;
}

/// Catalog filter passed to `GET /api/published-papers`.
///
/// Value-equality is required so it can serve as a Riverpod family key.
class PublishedPaperQuery {
  const PublishedPaperQuery({this.stream, this.subjectSlug, this.year});

  /// Stream slug (`natural_science` / `social_science`), optional.
  final String? stream;

  /// Subject slug, optional — ambiguous alone across streams, so the UI
  /// normally pairs it with [stream] (Decision 009/031).
  final String? subjectSlug;

  /// Exam year, optional.
  final int? year;

  @override
  bool operator ==(Object other) =>
      other is PublishedPaperQuery &&
      other.stream == stream &&
      other.subjectSlug == subjectSlug &&
      other.year == year;

  @override
  int get hashCode => Object.hash(stream, subjectSlug, year);

  @override
  String toString() =>
      'PublishedPaperQuery(stream: $stream, subjectSlug: $subjectSlug, year: $year)';
}

dynamic _field(Map<String, dynamic> json, String key) {
  if (!json.containsKey(key)) {
    throw FormatException('Catalog entry is missing "$key"');
  }
  return json[key];
}

String _string(Map<String, dynamic> json, String key) {
  final value = _field(json, key);
  if (value is! String || value.isEmpty) {
    throw FormatException('Catalog field "$key" must be a non-empty string');
  }
  return value;
}

String? _stringOrNull(Map<String, dynamic> json, String key) {
  if (!json.containsKey(key)) return null;
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Catalog field "$key" must be a string or null');
  }
  return value;
}

int _int(Map<String, dynamic> json, String key) {
  final value = _field(json, key);
  if (value is! int || value < 0) {
    throw FormatException('Catalog field "$key" must be a non-negative integer');
  }
  return value;
}
