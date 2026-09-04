import 'package:flutter/material.dart';

import '../../../../core/design/app_button.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/confirmation_screen.dart';
import '../../../../core/design/widgets/copyable_field.dart';

/// Step 4 — Confirmation.
///
/// Deliberately calm, not celebratory (no confetti/exclamation-heavy
/// tone) — this reads as a receipt, which stays appropriate even if the
/// request is later rejected. No back button: this is a landing point,
/// not a reversible step in the sequence.
class Step4Confirmation extends StatelessWidget {
  const Step4Confirmation({
    super.key,
    required this.requestId,
    required this.onViewPaymentStatus,
    required this.onDone,
  });

  final String requestId;
  final VoidCallback onViewPaymentStatus;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Terminal state — disable the hardware/gesture back action so it
      // doesn't re-enter the submission stepper.
      canPop: false,
      child: ConfirmationScreen(
        headline: 'Payment Submitted',
        detail: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CopyableField(value: 'Request #$requestId'),
            const SizedBox(height: AppSpacing.spaceMd),
            const Text(
              "We'll review this and unlock your content within 1–2 days. "
              'You can check status anytime in Payment History.',
              style: AppTypography.typeBody,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ConfirmationAction(
            label: 'View Payment Status',
            onPressed: onViewPaymentStatus,
          ),
          ConfirmationAction(
            label: 'Done',
            variant: AppButtonVariant.text,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}
