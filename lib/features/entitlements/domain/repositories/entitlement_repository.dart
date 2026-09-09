import '../models/entitlement.dart';

/// Repository for Entitlement records (Decisions 012, 017, 033).
///
/// Entitlements are server-authoritative state cached locally for offline
/// access (Decision 017). Sync direction is server → device only; the device
/// is never the source of truth for entitlement state.
///
/// The local cache is replaced atomically on each sync — there is no
/// client-side grant or revoke. Revocation happens server-side (refund,
/// chargeback, fraud) and reaches the device on the next entitlement refresh
/// (Decision 033).
abstract interface class EntitlementRepository {
  /// Return all entitlements cached for this install.
  Future<List<Entitlement>> getByInstallId(String installId);

  /// Return the active entitlement for a specific stream, or `null` if none.
  Future<Entitlement?> getActiveByInstallIdAndStreamId(
    String installId,
    int streamId,
  );

  /// Replace the local entitlement cache for this install with server state.
  ///
  /// This is the only write path — sync direction is server → device only
  /// (Decision 017). The caller is the sync layer receiving the server's
  /// authoritative entitlement list; the repository is never the source of
  /// truth.
  Future<void> syncFromServer(String installId, List<Entitlement> entitlements);
}
