/// Canonical proof-type values persisted locally.
enum ProofType { screenshot, transactionId }

/// Server-authoritative payment-request states (Decision 036).
///
/// Exactly three persisted states: `pending`, `verified`, `rejected`.
/// `submitted` is the event that creates a `pending` row.
/// `entitled` is NEVER a payment state — entitlement is a separate entity.
enum PaymentRequestStatus { pending, verified, rejected }

/// Local representation of a payment request (Decisions 013, 023, 036).
///
/// The canonical identifier is `requestId` — a UUID generated at submission
/// (Decision 023).  The local database is a cache of server state (Decision
/// 017); sync direction is server → device only.
class PaymentRequest {
  const PaymentRequest({
    required this.requestId,
    required this.installId,
    required this.streamId,
    required this.proofType,
    required this.proofValue,
    required this.status,
    required this.submittedAt,
    this.rejectionReason,
    this.verifiedAt,
  });

  final String requestId;
  final String installId;
  final int streamId;
  final ProofType proofType;
  final String proofValue;
  final PaymentRequestStatus status;
  final String submittedAt;
  final String? rejectionReason;
  final String? verifiedAt;
}
