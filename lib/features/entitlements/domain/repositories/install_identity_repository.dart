import '../models/install_identity.dart';

/// Repository for the local install identity (Decision 032).
///
/// The install identity is a persistent, anonymous UUID generated on-device at
/// first launch and never reset except by reinstall. It is the sole trust
/// anchor for backend calls at MVP — payment submission and entitlement sync.
///
/// This is a singleton row (enforced by `CHECK (id = 1)` on the table). The
/// repository ensures the row exists exactly once.
abstract interface class InstallIdentityRepository {
  /// Ensure the install identity exists, generating it on first call.
  ///
  /// Returns the identity on success. This is idempotent — calling it again
  /// returns the same identity without modification.
  Future<InstallIdentity> ensureCreated();

  /// Retrieve the current install identity, or `null` if not yet created.
  Future<InstallIdentity?> get();
}
