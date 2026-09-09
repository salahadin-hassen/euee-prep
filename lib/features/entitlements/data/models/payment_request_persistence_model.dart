/// Data-layer model for a payment request row.
///
/// Maps 1:1 to the `payment_requests` Drift table.  Status and proof-type
/// are stored as raw strings (matching the SQLite CHECK constraints) and
/// converted to/from domain enums at the repository boundary.
class PaymentRequestPersistenceModel {
  PaymentRequestPersistenceModel({
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
  final String proofType;
  final String proofValue;
  final String status;
  final String submittedAt;
  final String? rejectionReason;
  final String? verifiedAt;
}
