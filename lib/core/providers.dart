import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../features/progress/data/local_data_sources/attempt_local_data_source.dart';
import '../features/progress/data/repositories/attempt_repository_impl.dart';
import '../features/progress/domain/repositories/attempt_repository.dart';
import '../features/streams/data/local_data_sources/stream_local_data_source.dart';
import '../features/streams/data/repositories/stream_repository_impl.dart';
import '../features/streams/domain/repositories/stream_repository.dart';
import '../features/subjects/data/local_data_sources/subject_local_data_source.dart';
import '../features/subjects/data/repositories/subject_repository_impl.dart';
import '../features/subjects/domain/models/subject.dart' as domain;
import '../features/subjects/domain/repositories/subject_repository.dart';
import 'database/app_database.dart';

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
  );
});

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
