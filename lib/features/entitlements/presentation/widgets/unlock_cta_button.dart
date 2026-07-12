import 'package:flutter/material.dart';

import '../../../../core/design/app_button.dart';
import '../models/payment_request_ui_model.dart';

/// The single, state-driven call-to-action shown at the bottom of a
/// PaymentRequestCard.
///
/// Only two states render a CTA at all — [PaymentRequestStatus.entitled]
/// ("Go to Subjects") and [PaymentRequestStatus.rejected] ("Submit New
/// Payment"). All other states are informational-only and show nothing.
///
/// This mapping is centralized here (rather than as if/else branches
/// inside PaymentRequestCard) so that card widget doesn't accumulate
/// branching logic as more states are potentially added later.
class UnlockCtaButton extends StatelessWidget {
  const UnlockCtaButton({
    super.key,
    required this.status,
    this.onGoToSubjects,
    this.onSubmitNewPayment,
  });

  final PaymentRequestStatus status;

  /// TODO(integration): wire to navigation once routing is owned by the
  /// app shell. Left nullable/no-op here — this is presentation-only.
  final VoidCallback? onGoToSubjects;

  /// TODO(integration): wire to the payment submission flow's entry
  /// point once that route exists.
  final VoidCallback? onSubmitNewPayment;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      PaymentRequestStatus.entitled => AppButton(
          label: 'Go to Subjects',
          variant: AppButtonVariant.secondary,
          onPressed: onGoToSubjects,
        ),
      PaymentRequestStatus.rejected => AppButton(
          label: 'Submit New Payment',
          variant: AppButtonVariant.primary,
          onPressed: onSubmitNewPayment,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
