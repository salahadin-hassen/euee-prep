import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';

import 'package:euee_prep/core/network/network_client.dart';
import 'package:euee_prep/features/content/domain/models/content_pack_file.dart';
import 'package:euee_prep/features/content/domain/services/content_import_checksum.dart';
import 'package:euee_prep/features/exams/domain/models/published_paper.dart';

const fixturePath = 'test/features/content/fixtures/physics_euee_pack_v3.json';

String fixtureJson() => File(fixturePath).readAsStringSync();

/// Applies [change] to the fixture, then re-signs it so the checksum stays
/// valid — the test targets the mutation, not the checksum.
String mutateFixture(void Function(Map<String, dynamic> map) change) {
  final map = jsonDecode(fixtureJson()) as Map<String, dynamic>;
  change(map);
  return resignFixture(map);
}

/// Changes `pack_version` and re-signs the fixture.
String reversionedFixture(String packVersion) =>
    mutateFixture((map) => map['pack_version'] = packVersion);

String resignFixture(Map<String, dynamic> map) {
  map['checksum'] = '';
  final pack = ContentPackFile.fromJson(map);
  map['checksum'] = ContentChecksum.compute(pack);
  return jsonEncode(map);
}

/// The fixture with a broken checksum (intentionally not re-signed).
String corruptChecksumFixture() {
  final map = jsonDecode(fixtureJson()) as Map<String, dynamic>;
  map['checksum'] = 'fnv1a64:deadbeefdeadbeef';
  return jsonEncode(map);
}

/// Builds a single-entry ZIP containing [content] under [name].
List<int> zipWithFile(String name, String content) {
  final bytes = utf8.encode(content);
  final archive = Archive()..addFile(ArchiveFile(name, bytes.length, bytes));
  return ZipEncoder().encode(archive) ?? (throw StateError('ZIP encode failed'));
}

/// The ZIP Content Studio publishes: one `content-pack.json` entry.
List<int> packZip(String packJson) => zipWithFile('content-pack.json', packJson);

/// Derives the catalog entry for a pack JSON document, as the backend would.
PublishedPaper paperFromPackJson(
  String packJson, {
  String? downloadUrl,
  String? packVersion,
  String? minimumAppVersion,
  int? sizeBytes,
}) {
  final map = jsonDecode(packJson) as Map<String, dynamic>;
  final subject = map['subject'] as Map<String, dynamic>;
  final paper = map['paper'] as Map<String, dynamic>;
  final packId = map['pack_id'] as String;
  final version = packVersion ?? map['pack_version'] as String;
  return PublishedPaper(
    packId: packId,
    subjectSlug: subject['slug'] as String,
    subjectTitle: subject['title'] as String,
    stream: map['stream'] as String,
    year: paper['year'] as int,
    title: paper['title'] as String,
    questionCount: paper['question_count'] as int,
    packVersion: version,
    sizeBytes: sizeBytes ?? 1024,
    storagePath: '$packId/$version.zip',
    publishedAt: '2026-10-01T00:00:00.000Z',
    minimumAppVersion: minimumAppVersion ?? map['minimum_app_version'] as String,
    updatedAt: '2026-10-01T00:00:00.000Z',
    downloadUrl: downloadUrl ?? 'https://storage.test/$packId/$version.zip',
  );
}

String catalogBody(List<PublishedPaper> papers) => jsonEncode({
      'papers': [for (final paper in papers) paper.toJson()],
    });

/// Scripted [NetworkClient] for tests: canned catalog responses and ZIP
/// bytes, plus failure injection. Records every request it receives.
class FakeNetworkClient implements NetworkClient {
  FakeNetworkClient({
    this.catalogBody,
    this.downloadBytes,
    this.downloadError,
    this.chunkSize = 8,
  });

  /// Response for [getString] (the catalog), or `null` to fail with
  /// [NetworkRequestException].
  String? catalogBody;

  /// Bytes served for [downloadToFile].
  List<int>? downloadBytes;

  /// When set, [downloadToFile] throws it instead of writing anything.
  Object? downloadError;

  /// Bytes written per scripted progress tick.
  int chunkSize;

  final List<Uri> stringRequests = [];
  final List<Uri> downloadRequests = [];

  bool get wasDownloadRequested => downloadRequests.isNotEmpty;

  @override
  Future<String> getString(Uri uri) async {
    stringRequests.add(uri);
    final body = catalogBody;
    if (body == null) {
      throw NetworkRequestException(uri, 'no catalog response scripted');
    }
    return body;
  }

  @override
  Future<void> downloadToFile(
    Uri uri, {
    required File destination,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    downloadRequests.add(uri);
    final error = downloadError;
    if (error != null) throw error;

    final bytes = downloadBytes;
    if (bytes == null) {
      throw NetworkRequestException(uri, 'no download bytes scripted');
    }

    await destination.parent.create(recursive: true);
    final handle = await destination.open(mode: FileMode.write);
    try {
      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        final end = math.min(offset + chunkSize, bytes.length);
        await handle.writeFrom(bytes, offset, end);
        onProgress?.call(end, bytes.length);
      }
      await handle.flush();
    } finally {
      await handle.close();
    }
  }
}
