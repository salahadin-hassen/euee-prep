// TEMPORARY MOCK DATA SOURCE.
//
// This exists only so payment_history_screen.dart can be reviewed and
// run standalone before Riverpod/Drift/repositories are wired up. It
// contains no business logic — it's a static list matching the UI
// model shape.
//
// TODO(integration): Delete this file once a real provider (e.g.
// paymentRequestListProvider) supplies PaymentRequestUiModel instances
// derived from the actual Entitlement/PaymentRequest repositories.
// payment_history_screen.dart should only need its data source swapped,
// not its widget tree.

import '../models/payment_request_ui_model.dart';

class MockPaymentRequests {
  MockPaymentRequests._();

  static List<PaymentRequestUiModel> all() {
    final now = DateTime(2026, 7, 12);
    return [
      PaymentRequestUiModel(
        requestId: 'EP-9012',
        streamName: 'Natural Science',
        status: PaymentRequestStatus.pending,
        submittedAt: now.subtract(const Duration(days: 2)),
      ),
      PaymentRequestUiModel(
        requestId: 'EP-8834',
        streamName: 'Natural Science',
        status: PaymentRequestStatus.rejected,
        submittedAt: now.subtract(const Duration(days: 6)),
        rejectionReason:
            "Screenshot didn't clearly show the transaction reference number.",
      ),
      PaymentRequestUiModel(
        requestId: 'EP-7021',
        streamName: 'Social Science',
        status: PaymentRequestStatus.entitled,
        submittedAt: now.subtract(const Duration(days: 40)),
        verifiedAt: now.subtract(const Duration(days: 39)),
      ),
      PaymentRequestUiModel(
        requestId: 'EP-6650',
        streamName: 'Social Science',
        status: PaymentRequestStatus.rejected,
        submittedAt: now.subtract(const Duration(days: 42)),
        rejectionReason: null, // exercises the "no reason provided" fallback
      ),
    ];
  }

  /// Exercises the empty-state branch.
  static List<PaymentRequestUiModel> empty() => const [];
}
