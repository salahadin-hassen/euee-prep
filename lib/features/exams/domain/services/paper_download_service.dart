import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../../../core/network/network_client.dart';
import '../../../../core/utilities/semver.dart';
import '../../../content/domain/models/content_pack.dart';
import '../../../content/domain/repositories/content_pack_repository.dart';
import '../../../content/domain/services/content_import_issue.dart';
import '../../../content/domain/services/content_import_service.dart';
import '../models/published_paper.dart';
import '../repositories/published_paper_repository.dart';

/// Why a paper download/import failed — the exhaustive set the UI maps onto
/// a clean error state.
enum PaperDownloadFailure {
  /// Connection-level failure (DNS/TLS/socket).
  network,

  /// The server answered with a non-200 status.
  http,

  /// The downloaded artifact was not a readable ZIP.
  invalidZip,

  /// The ZIP did not contain `content-pack.json`.
  missingContentPack,

  /// `content-pack.json` was not valid JSON.
  malformedJson,

  /// The pack's checksum did not match its contents.
  checksumMismatch,

  /// The pack requires a newer app version.
  incompatibleAppVersion,

  /// The existing import pipeline rejected the pack (rolled back).
  importFailed,

  /// The device ran out of storage while writing the ZIP.
  insufficientStorage,

  /// Anything else (misconfiguration, unexpected I/O, …).
  unknown,
}

/// Outcome of a [PaperDownloadService.download] call — data, not exceptions,
/// so callers can surface it directly as UI state.
class PaperDownloadResult {
  const PaperDownloadResult._({
    required this.success,
    required this.alreadyInstalled,
    this.failure,
    this.message,
    this.pack,
  });

  /// The pack is now installed (freshly imported, or already present).
  factory PaperDownloadResult.installed(
    ContentPack pack, {
    required bool alreadyInstalled,
  }) =>
      PaperDownloadResult._(
        success: true,
        alreadyInstalled: alreadyInstalled,
        pack: pack,
      );

  /// The download/import failed; [failure] classifies it.
  factory PaperDownloadResult.failed(PaperDownloadFailure failure, String message) =>
      PaperDownloadResult._(
        success: false,
        alreadyInstalled: false,
        failure: failure,
        message: message,
      );

  final bool success;

  /// True when nothing had to be downloaded because the version was already
  /// installed (same-or-newer check).
  final bool alreadyInstalled;

  final PaperDownloadFailure? failure;
  final String? message;

  /// The installed content pack (local row) after success.
  final ContentPack? pack;

  bool get isSuccess => success;
}

/// Download progress reported while the ZIP streams to disk.
class PaperDownloadProgress {
  const PaperDownloadProgress({required this.receivedBytes, this.totalBytes});

  final int receivedBytes;
  final int? totalBytes;

  /// `0.0`–`1.0`, or `null` when the total is unknown.
  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (receivedBytes / total).clamp(0.0, 1.0);
  }
}

/// Executes the download half of the published-paper pipeline:
///
/// skip-if-installed → app-version gate → stream ZIP to a temp dir →
/// validate ZIP → extract `content-pack.json` → hand it to the existing
/// [ContentImportService] (v3 schema validation + FNV-1a checksum + atomic
/// import) → clean up temp files.
///
/// It deliberately owns no checksum, schema, or database logic — a failed
/// update therefore leaves the previously installed version untouched,
/// because the import transaction never ran.
class PaperDownloadService {
  PaperDownloadService({
    required PublishedPaperRepository repository,
    required ContentPackRepository contentPackRepository,
    required ContentImportService importService,
    required NetworkClient network,
    required Future<Directory> Function() temporaryDirectory,
  })  : _repository = repository,
        _contentPackRepository = contentPackRepository,
        _importService = importService,
        _network = network,
        _temporaryDirectory = temporaryDirectory;

  static const String _zipFileName = 'content-pack.zip';
  static const String _packFileName = 'content-pack.json';

  final PublishedPaperRepository _repository;
  final ContentPackRepository _contentPackRepository;
  final ContentImportService _importService;
  final NetworkClient _network;
  final Future<Directory> Function() _temporaryDirectory;

  /// Downloads and imports [paper]; never throws for expected failures.
  Future<PaperDownloadResult> download(
    PublishedPaper paper, {
    void Function(PaperDownloadProgress progress)? onProgress,
  }) async {
    // 1. Skip when the same or a newer version is already installed.
    final PaperInstallStatus status;
    try {
      status = await _repository.installStatus(paper);
    } catch (e) {
      return PaperDownloadResult.failed(
        PaperDownloadFailure.unknown,
        'Could not determine installed version: $e',
      );
    }
    if (status.state == PaperInstallState.installed) {
      final installedPack = await _contentPackRepository.getLatestForPackId(
        paper.packId,
      );
      if (installedPack != null) {
        return PaperDownloadResult.installed(installedPack, alreadyInstalled: true);
      }
      // Status and local rows disagreed — fall through and download again;
      // the idempotent import makes this safe.
    }

    // 2. Fail fast on an incompatible app version — don't burn bandwidth.
    if (compareSemVer(paper.minimumAppVersion, _importService.currentAppVersion) > 0) {
      return PaperDownloadResult.failed(
        PaperDownloadFailure.incompatibleAppVersion,
        'This paper requires app version ${paper.minimumAppVersion} or newer '
        '(running ${_importService.currentAppVersion}).',
      );
    }

    Directory? tempDir;
    try {
      // 3. Stream the ZIP into a private temp directory.
      final base = await _temporaryDirectory();
      tempDir = await base.createTemp('paper_download_');
      final zipFile = File(p.join(tempDir.path, _zipFileName));

      final uri = _downloadUri(paper);
      await _network.downloadToFile(
        uri,
        destination: zipFile,
        onProgress: (received, totalBytes) {
          onProgress?.call(PaperDownloadProgress(
            receivedBytes: received,
            // Fall back to the catalog's size when the server omits the
            // content length, so the UI always has a total to show.
            totalBytes: totalBytes ?? paper.sizeBytes,
          ));
        },
      );

      // 4. Validate the artifact and extract content-pack.json.
      final String packJson;
      try {
        packJson = await _extractPackJson(zipFile);
      } on _InvalidZipException {
        return PaperDownloadResult.failed(
          PaperDownloadFailure.invalidZip,
          'The downloaded file is not a valid ZIP archive.',
        );
      } on _MissingPackJsonException {
        return PaperDownloadResult.failed(
          PaperDownloadFailure.missingContentPack,
          'The downloaded archive does not contain $_packFileName.',
        );
      }

      // 5. Hand off to the existing v3 validation/checksum/import pipeline.
      final result = await _importService.import(packJson);
      if (result.isSuccess || result.alreadyImported) {
        return PaperDownloadResult.installed(
          result.pack!,
          alreadyInstalled: result.alreadyImported,
        );
      }
      return _mapImportFailure(result);
    } on NetworkRequestException catch (e) {
      return PaperDownloadResult.failed(
        PaperDownloadFailure.network,
        'Could not reach the download server: $e',
      );
    } on HttpStatusException catch (e) {
      return PaperDownloadResult.failed(
        PaperDownloadFailure.http,
        'Download failed with HTTP ${e.statusCode}.',
      );
    } on InsufficientStorageException {
      return PaperDownloadResult.failed(
        PaperDownloadFailure.insufficientStorage,
        'Not enough storage space to download this paper.',
      );
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 28 /* ENOSPC */) {
        return PaperDownloadResult.failed(
          PaperDownloadFailure.insufficientStorage,
          'Not enough storage space to download this paper.',
        );
      }
      return PaperDownloadResult.failed(
        PaperDownloadFailure.unknown,
        'File system error while downloading: ${e.message}',
      );
    } catch (e) {
      return PaperDownloadResult.failed(
        PaperDownloadFailure.unknown,
        'Unexpected error while downloading: $e',
      );
    } finally {
      // 6. Always remove the temporary ZIP (success or failure).
      if (tempDir != null) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {
          // Temp dirs are disposable; a leftover file must not mask the
          // download outcome.
        }
      }
    }
  }

  Uri _downloadUri(PublishedPaper paper) {
    final url = paper.downloadUrl;
    if (url.isEmpty) {
      throw const FormatException('download_url is empty');
    }
    return Uri.parse(url);
  }

  Future<String> _extractPackJson(File zipFile) async {
    final List<int> bytes;
    try {
      bytes = await zipFile.readAsBytes();
    } on FileSystemException {
      rethrow; // surfaced by the caller's FileSystemException handler
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const _InvalidZipException();
    }

    final entries = archive.files.where((f) => f.name == _packFileName);
    if (entries.isEmpty) throw const _MissingPackJsonException();

    final content = entries.first.content;
    if (content is String) return content;
    if (content is List<int>) {
      return utf8.decode(content, allowMalformed: true);
    }
    throw const _InvalidZipException();
  }

  PaperDownloadResult _mapImportFailure(ContentImportResult result) {
    final issues = result.issues;
    final message = issues.isEmpty
        ? 'Import failed.'
        : issues.map((issue) => issue.message).join('\n');
    final failure = switch (issues.isEmpty
        ? null
        : issues.first.code) {
      ContentImportIssueCode.malformedJson => PaperDownloadFailure.malformedJson,
      ContentImportIssueCode.checksumMismatch => PaperDownloadFailure.checksumMismatch,
      ContentImportIssueCode.incompatibleAppVersion =>
        PaperDownloadFailure.incompatibleAppVersion,
      ContentImportIssueCode.validation ||
      ContentImportIssueCode.importFailed =>
        PaperDownloadFailure.importFailed,
      null => PaperDownloadFailure.unknown,
    };
    return PaperDownloadResult.failed(failure, message);
  }
}

class _InvalidZipException implements Exception {
  const _InvalidZipException();
}

class _MissingPackJsonException implements Exception {
  const _MissingPackJsonException();
}
