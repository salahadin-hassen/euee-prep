import '../models/payment_request.dart';

/// Repository for PaymentRequest records (Decisions 013, 017, 023, 036).
///
/// PaymentRequests are server-authoritative state cached locally for offline
/// access (Decision 017).  Sync direction is server → device only; the device
/// is never the source of truth for payment-request state.
///
/// The canonical identifier is `requestId` (Decision 023) — a UUID generated
/// at submission, not the proof itself.
///
/// The local cache is replaced atomically on each sync — there is no
/// client-side verify or reject.  Verification happens server-side and
/// reaches the device on the next sync (Decision 036).
abstract interface class PaymentRequestRepository {
  /// Return all payment requests cached for this install.
  Future<List<PaymentRequest>> getByInstallId(String installId);

  /// Return the payment request with the given canonical request ID, or null.
  Future<PaymentRequest?> getByRequestId(String requestId);

  /// Replace the local payment-request cache for this install with server
  /// state.
  ///
  /// This is the only write path — sync direction is server → device only
  /// (Decision 017).  The caller is the sync layer receiving the server's
  /// authoritative list; the repository is never the source of truth.
  Future<void> syncFromServer(
    String installId,
    List<PaymentRequest> requests,
  );
}
