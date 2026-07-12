// Local UI model — presentation layer only.
//
// This is intentionally NOT the domain model. The real PaymentRequest
// domain entity (Decision 012/013/017/023) is owned by the data/domain
// layers and will be built by another team. This model exists so widgets
// in this feature have a typed, stable shape to render against while
// mock data stands in for the repository.
//
// TODO(integration): When the real repository/provider is wired up,
// replace PaymentRequestUiModel.fromMock(...) call sites with a mapper
// from the domain PaymentRequest model to this UI model. Widgets should
// not need to change.

enum PaymentRequestStatus {
  submitted,
  pending,
  verified,
  entitled,
  rejected,
}

class PaymentRequestUiModel {
  const PaymentRequestUiModel({
    required this.requestId,
    required this.streamName,
    required this.status,
    required this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
  });

  final String requestId;
  final String streamName;
  final PaymentRequestStatus status;
  final DateTime submittedAt;
  final DateTime? verifiedAt;

  /// Only meaningful when [status] is [PaymentRequestStatus.rejected].
  /// Nullable to represent the "admin didn't fill in a reason" edge case
  /// called out in the Payment History design review — the UI must
  /// degrade gracefully with fallback copy, never show a blank reason.
  final String? rejectionReason;
}
