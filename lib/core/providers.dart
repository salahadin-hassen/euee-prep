import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../features/content/data/local_data_sources/content_pack_local_data_source.dart';
import '../features/content/data/local_data_sources/drift_import_transaction.dart';
import '../features/content/data/local_data_sources/exam_local_data_source.dart';
import '../features/content/data/local_data_sources/question_local_data_source.dart';
import '../features/content/data/repositories/content_pack_repository_impl.dart';
import '../features/content/data/repositories/exam_repository_impl.dart';
import '../features/content/data/repositories/question_repository_impl.dart';
import '../features/content/domain/models/exam.dart' as exam_model;
import '../features/content/domain/repositories/content_pack_repository.dart';
import '../features/content/domain/repositories/exam_repository.dart';
import '../features/content/domain/repositories/question_repository.dart';
import '../features/content/domain/services/content_import_service.dart';
import '../features/entitlements/data/local_data_sources/entitlement_local_data_source.dart';
import '../features/entitlements/data/local_data_sources/install_identity_local_data_source.dart';
import '../features/entitlements/data/repositories/entitlement_repository_impl.dart';
import '../features/entitlements/data/repositories/install_identity_repository_impl.dart';
import '../features/entitlements/domain/models/entitlement.dart'
    as entitlement_domain;
import '../features/entitlements/domain/repositories/entitlement_repository.dart';
import '../features/entitlements/domain/repositories/install_identity_repository.dart';
import '../features/exams/data/remote_data_sources/published_paper_remote_data_source.dart';
import '../features/exams/data/repositories/published_paper_repository_impl.dart';
import '../features/exams/domain/models/published_paper.dart';
import '../features/exams/domain/repositories/published_paper_repository.dart';
import '../features/exams/domain/services/paper_download_service.dart';
import '../features/exams/presentation/paper_download_controller.dart';
import '../features/progress/data/local_data_sources/attempt_local_data_source.dart';
import '../features/progress/data/repositories/attempt_repository_impl.dart';
import '../features/progress/domain/repositories/attempt_repository.dart';
import '../features/streams/data/local_data_sources/stream_local_data_source.dart';
import '../features/streams/data/repositories/stream_repository_impl.dart';
import '../features/streams/domain/models/stream_model.dart';
import '../features/streams/domain/repositories/stream_repository.dart';
import '../features/subjects/data/local_data_sources/subject_local_data_source.dart';
import '../features/subjects/data/repositories/subject_repository_impl.dart';
import '../features/subjects/domain/models/subject.dart' as domain;
import '../features/subjects/domain/repositories/subject_repository.dart';
import 'config/app_config.dart';
import 'database/app_database.dart';
import 'network/network_client.dart';

/// Singleton AppDatabase — one instance for the app's lifetime.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// ---------------------------------------------------------------------------
// Subjects
// ---------------------------------------------------------------------------

final subjectLocalDataSourceProvider = Provider<SubjectLocalDataSource>(
  (ref) => SubjectLocalDataSource(ref.watch(databaseProvider)),
);

final subjectRepositoryProvider = Provider<SubjectRepository>(
  (ref) => SubjectRepositoryImpl(ref.watch(subjectLocalDataSourceProvider)),
);

/// All subjects for a given stream, fetched from the repository.
///
/// Returns an empty list when no subjects exist for the stream (e.g. before
/// a content pack has been imported).
final subjectsByStreamProvider =
    FutureProvider.autoDispose.family<List<domain.Subject>, int>(
  (ref, streamId) async {
    final repo = ref.watch(subjectRepositoryProvider);
    return repo.getByStreamId(streamId);
  },
);

/// Real paper/question/progress counts for every subject in a stream.
///
/// Derived from the Exam and Attempt tables in a single pass — no
/// per-subject query fan-out. Attempt history is append-only
/// (Decision 016) and is recalculated on read, never cached.
final subjectStatsForStreamProvider =
    FutureProvider.autoDispose.family<Map<int, SubjectStats>, int>(
  (ref, streamId) async {
    final subjects =
        await ref.watch(subjectRepositoryProvider).getByStreamId(streamId);
    final exams = await ref.watch(examRepositoryProvider).getAll();
    final attempts = await ref.watch(attemptRepositoryProvider).getAll();

    final examsBySubject = <int, List<exam_model.Exam>>{};
    for (final exam in exams) {
      examsBySubject.putIfAbsent(exam.subjectId, () => []).add(exam);
    }
    final attemptedQuestionIds = attempts.map((a) => a.questionId).toSet();

    final result = <int, SubjectStats>{};
    for (final subject in subjects) {
      final questionIds = <int>{};
      final subjectExams = examsBySubject[subject.id] ?? const [];
      for (final exam in subjectExams) {
        questionIds.addAll(exam.questionIds);
      }
      result[subject.id] = SubjectStats(
        paperCount: subjectExams.length,
        questionCount: questionIds.length,
        answeredCount: questionIds.intersection(attemptedQuestionIds).length,
      );
    }
    return result;
  },
);

/// Paper / question / answered counts for one subject, derived from real
/// Exam and Attempt rows.
class SubjectStats {
  const SubjectStats({
    required this.paperCount,
    required this.questionCount,
    required this.answeredCount,
  });

  /// Number of imported exam papers ("papers") for the subject.
  final int paperCount;

  /// Distinct questions across the subject's papers.
  final int questionCount;

  /// Distinct questions from those papers that have been answered.
  final int answeredCount;

  /// 0.0–1.0, or `null` when the subject has no questions imported yet.
  double? get progress =>
      questionCount == 0 ? null : answeredCount / questionCount;
}

// ---------------------------------------------------------------------------
// Streams
// ---------------------------------------------------------------------------

final streamLocalDataSourceProvider = Provider<StreamLocalDataSource>(
  (ref) => StreamLocalDataSource(ref.watch(databaseProvider)),
);

final streamRepositoryProvider = Provider<StreamRepository>(
  (ref) => StreamRepositoryImpl(ref.watch(streamLocalDataSourceProvider)),
);

/// The Preferred Stream id, read from the local settings table.
///
/// Returns `null` when the user has not yet completed onboarding. The
/// presentation layer handles this as a distinct state (prompt for stream
/// selection), not as an error.
final preferredStreamIdProvider = FutureProvider<int?>((ref) async {
  final db = ref.watch(databaseProvider);
  final value = await db.getSetting('preferred_stream_id');
  return value != null ? int.tryParse(value) : null;
});

/// All streams, loaded once. Screens derive display names from this
/// instead of kicking off a fresh repository future on every build.
final allStreamsProvider = FutureProvider<List<StreamModel>>((ref) {
  return ref.watch(streamRepositoryProvider).getAll();
});

// ---------------------------------------------------------------------------
// Install Identity
// ---------------------------------------------------------------------------

final installIdentityLocalDataSourceProvider =
    Provider<InstallIdentityLocalDataSource>(
  (ref) => InstallIdentityLocalDataSource(ref.watch(databaseProvider)),
);

final installIdentityRepositoryProvider = Provider<InstallIdentityRepository>(
  (ref) => InstallIdentityRepositoryImpl(
    ref.watch(installIdentityLocalDataSourceProvider),
  ),
);

/// Ensures the install identity exists, returning the install ID string.
///
/// This is the canonical source of the install ID for entitlement lookups.
final installIdProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(installIdentityRepositoryProvider);
  final identity = await repo.ensureCreated();
  return identity.installId;
});

// ---------------------------------------------------------------------------
// Entitlements
// ---------------------------------------------------------------------------

final entitlementLocalDataSourceProvider = Provider<EntitlementLocalDataSource>(
  (ref) => EntitlementLocalDataSource(ref.watch(databaseProvider)),
);

final entitlementRepositoryProvider = Provider<EntitlementRepository>(
  (ref) => EntitlementRepositoryImpl(
    ref.watch(entitlementLocalDataSourceProvider),
  ),
);

/// Returns the active entitlement for a given stream, or `null` if none.
///
/// Depends on [installIdProvider] — if the install identity has not been
/// created yet this will emit an error (fail closed).
final activeEntitlementForStreamProvider = FutureProvider.autoDispose
    .family<entitlement_domain.Entitlement?, int>((ref, streamId) async {
  final installId = await ref.watch(installIdProvider.future);
  final repo = ref.watch(entitlementRepositoryProvider);
  return repo.getActiveByInstallIdAndStreamId(installId, streamId);
});

/// Human-readable name for a stream slug.
String streamDisplayName(String slug) {
  switch (slug) {
    case 'natural_science':
      return 'Natural Science';
    case 'social_science':
      return 'Social Science';
    default:
      return slug;
  }
}

// ---------------------------------------------------------------------------
// Content (Exam, Question, ContentPack)
// ---------------------------------------------------------------------------

final contentPackLocalDataSourceProvider = Provider<ContentPackLocalDataSource>(
  (ref) => ContentPackLocalDataSource(ref.watch(databaseProvider)),
);

final contentPackRepositoryProvider = Provider<ContentPackRepository>(
  (ref) =>
      ContentPackRepositoryImpl(ref.watch(contentPackLocalDataSourceProvider)),
);

final examLocalDataSourceProvider = Provider<ExamLocalDataSource>(
  (ref) => ExamLocalDataSource(ref.watch(databaseProvider)),
);

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ExamRepositoryImpl(ref.watch(examLocalDataSourceProvider)),
);

final questionLocalDataSourceProvider = Provider<QuestionLocalDataSource>(
  (ref) => QuestionLocalDataSource(ref.watch(databaseProvider)),
);

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) =>
      QuestionRepositoryImpl(ref.watch(questionLocalDataSourceProvider)),
);

/// Exams for a given subject, ordered by year.
final examsBySubjectProvider =
    FutureProvider.autoDispose.family<List<exam_model.Exam>, int>(
  (ref, subjectId) async {
    final repo = ref.watch(examRepositoryProvider);
    return repo.getBySubjectId(subjectId);
  },
);

// ---------------------------------------------------------------------------
// Import
// ---------------------------------------------------------------------------

final contentImportServiceProvider = Provider<ContentImportService>((ref) {
  return ContentImportService(
    contentPackRepository: ref.watch(contentPackRepositoryProvider),
    streamRepository: ref.watch(streamRepositoryProvider),
    subjectRepository: ref.watch(subjectRepositoryProvider),
    questionRepository: ref.watch(questionRepositoryProvider),
    examRepository: ref.watch(examRepositoryProvider),
    transaction: DriftImportTransaction(ref.watch(databaseProvider)),
    currentAppVersion: AppConfig.currentAppVersion,
  );
});

// ---------------------------------------------------------------------------
// Published papers (catalog + download)
// ---------------------------------------------------------------------------

/// The app's single HTTP seam (`dart:io`-backed; see `core/network`).
final networkClientProvider = Provider<NetworkClient>(
  (ref) => IoNetworkClient(),
);

final publishedPaperRemoteDataSourceProvider =
    Provider<PublishedPaperRemoteDataSource>(
  (ref) => PublishedPaperRemoteDataSource(
    network: ref.watch(networkClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
  ),
);

/// Catalog reads + installed-version lookups (reads only — importing stays
/// with `ContentImportService`).
final publishedPaperRepositoryProvider = Provider<PublishedPaperRepository>(
  (ref) => PublishedPaperRepositoryImpl(
    remote: ref.watch(publishedPaperRemoteDataSourceProvider),
    contentPackRepository: ref.watch(contentPackRepositoryProvider),
  ),
);

/// Where downloads are staged before validation (platform temp dir in the
/// app; overridable in tests).
final temporaryDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => getTemporaryDirectory,
);

/// Download pipeline: skip-if-installed → stream ZIP to temp → validate →
/// extract `content-pack.json` → existing import pipeline → cleanup.
final paperDownloadServiceProvider = Provider<PaperDownloadService>(
  (ref) => PaperDownloadService(
    repository: ref.watch(publishedPaperRepositoryProvider),
    contentPackRepository: ref.watch(contentPackRepositoryProvider),
    importService: ref.watch(contentImportServiceProvider),
    network: ref.watch(networkClientProvider),
    temporaryDirectory: ref.watch(temporaryDirectoryProvider),
  ),
);

/// Catalog entries for a query, each joined with its install status — the
/// list the Past Papers UI renders (Available / Installed / Update available).
final papersWithStatusProvider = FutureProvider.autoDispose
    .family<List<PaperAvailability>, PublishedPaperQuery>(
  (ref, query) async {
    final repository = ref.watch(publishedPaperRepositoryProvider);
    final papers = await repository.fetchPapers(
      stream: query.stream,
      subjectSlug: query.subjectSlug,
      year: query.year,
    );
    return repository.withInstallStatus(papers);
  },
);

/// Download lifecycle state (Downloading with progress / Installed / Failed).
final paperDownloadControllerProvider =
    NotifierProvider<PaperDownloadController, PaperDownloadState>(
  PaperDownloadController.new,
);

// ---------------------------------------------------------------------------
// Attempts
// ---------------------------------------------------------------------------

final attemptLocalDataSourceProvider = Provider<AttemptLocalDataSource>(
  (ref) => AttemptLocalDataSource(ref.watch(databaseProvider)),
);

final attemptRepositoryProvider = Provider<AttemptRepository>(
  (ref) =>
      AttemptRepositoryImpl(ref.watch(attemptLocalDataSourceProvider)),
);
