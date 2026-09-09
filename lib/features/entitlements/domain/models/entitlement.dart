enum EntitlementStatus { active, revoked }

class Entitlement {
  const Entitlement({
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
  final EntitlementStatus status;
  final String grantedAt;
  final String? revokedAt;
  final String? sourcePaymentRequestId;
}
