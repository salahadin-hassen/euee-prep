import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/domain/models/content_pack.dart';
import '../../../core/providers.dart';
import '../domain/models/published_paper.dart';
import '../domain/services/paper_download_service.dart';

/// Lifecycle of one download as the Past Papers UI sees it:
/// Downloading (with progress) → installed / failed. Availability itself
/// (Available / Installed / Update available) comes from
/// `papersWithStatusProvider`.
enum PaperDownloadPhase { idle, downloading, installed, failed }

/// Immutable snapshot exposed by [PaperDownloadController].
class PaperDownloadState {
  const PaperDownloadState._({
    required this.phase,
    this.paper,
    this.receivedBytes = 0,
    this.totalBytes,
    this.failure,
    this.message,
    this.installedVersion,
    this.alreadyInstalled = false,
  });

  const PaperDownloadState.idle() : this._(phase: PaperDownloadPhase.idle);

  factory PaperDownloadState.downloading(
    PublishedPaper paper, {
    int receivedBytes = 0,
    int? totalBytes,
  }) =>
      PaperDownloadState._(
        phase: PaperDownloadPhase.downloading,
        paper: paper,
        receivedBytes: receivedBytes,
        totalBytes: totalBytes ?? paper.sizeBytes,
      );

  factory PaperDownloadState.installed(
    PublishedPaper paper, {
    required String installedVersion,
    required bool alreadyInstalled,
  }) =>
      PaperDownloadState._(
        phase: PaperDownloadPhase.installed,
        paper: paper,
        installedVersion: installedVersion,
        alreadyInstalled: alreadyInstalled,
      );

  factory PaperDownloadState.failed(
    PublishedPaper paper, {
    required PaperDownloadFailure failure,
    required String message,
  }) =>
      PaperDownloadState._(
        phase: PaperDownloadPhase.failed,
        paper: paper,
        failure: failure,
        message: message,
      );

  final PaperDownloadPhase phase;
  final PublishedPaper? paper;
  final int receivedBytes;
  final int? totalBytes;
  final PaperDownloadFailure? failure;
  final String? message;
  final String? installedVersion;
  final bool alreadyInstalled;

  /// `0.0`–`1.0`, or `null` when unknown.
  double? get progress {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (receivedBytes / total).clamp(0.0, 1.0);
  }

  bool get isDownloading => phase == PaperDownloadPhase.downloading;
}

/// Drives a paper download and exposes it as Riverpod state.
///
/// One download at a time: starting a new one replaces the current state.
/// Success invalidates the catalog and the affected subject's exams so the
/// learner path (Subjects → Past Papers → Practice) sees the new content
/// immediately.
class PaperDownloadController extends Notifier<PaperDownloadState> {
  @override
  PaperDownloadState build() => const PaperDownloadState.idle();

  Future<PaperDownloadResult> download(PublishedPaper paper) async {
    final service = ref.read(paperDownloadServiceProvider);
    state = PaperDownloadState.downloading(paper);

    final result = await service.download(
      paper,
      onProgress: (progress) {
        state = PaperDownloadState.downloading(
          paper,
          receivedBytes: progress.receivedBytes,
          totalBytes: progress.totalBytes,
        );
      },
    );

    if (result.isSuccess) {
      final pack = result.pack!;
      state = PaperDownloadState.installed(
        paper,
        installedVersion: pack.packVersion,
        alreadyInstalled: result.alreadyInstalled,
      );
      if (!result.alreadyInstalled) _invalidateAfterInstall(pack);
    } else {
      state = PaperDownloadState.failed(
        paper,
        failure: result.failure ?? PaperDownloadFailure.unknown,
        message: result.message ?? 'Download failed.',
      );
    }
    return result;
  }

  /// Returns to idle (e.g. after the UI has shown the outcome).
  void reset() => state = const PaperDownloadState.idle();

  void _invalidateAfterInstall(ContentPack pack) {
    ref.invalidate(papersWithStatusProvider);
    ref.invalidate(examsBySubjectProvider(pack.subjectId));
  }
}
