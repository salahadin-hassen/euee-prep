import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/entitlements/data/local_data_sources/entitlement_local_data_source.dart';
import '../features/entitlements/data/local_data_sources/install_identity_local_data_source.dart';
import '../features/entitlements/data/repositories/entitlement_repository_impl.dart';
import '../features/entitlements/data/repositories/install_identity_repository_impl.dart';
import '../features/entitlements/domain/models/entitlement.dart'
    as entitlement_domain;
import '../features/entitlements/domain/repositories/entitlement_repository.dart';
import '../features/entitlements/domain/repositories/install_identity_repository.dart';
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
