class EntitlementPersistenceModel {
  EntitlementPersistenceModel({
    required this.id,
    required this.installId,
    required this.streamId,
    required this.status,
    required this.grantedAt,
    this.revokedAt,
    this.sourcePaymentRequestId,
  });

  final int id;
  final String installId;
  final int streamId;
  final String status;
  final String grantedAt;
  final String? revokedAt;
  final String? sourcePaymentRequestId;
}
