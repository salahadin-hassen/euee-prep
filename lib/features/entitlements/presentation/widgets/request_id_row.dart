import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/copyable_field.dart';

/// Displays a payment Request ID with a tap-to-copy action.
///
/// Per Decision 023, the request ID — not the screenshot or typed
/// transaction ID — is the canonical identifier for a payment request.
/// This widget exists to make that ID visible and copyable everywhere
/// it appears (Payment History cards, submission confirmation screen).
///
/// Built on the shared [CopyableField] primitive (refactored per the
/// design review note to avoid duplicating copy-button logic between
/// this widget and the Payment Submission flow's payment-instructions
/// field).
class RequestIdRow extends StatelessWidget {
  const RequestIdRow({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return CopyableField(
      value: 'Request #$requestId',
      valueStyle: AppTypography.typeCaption,
      semanticLabel: 'Request ID $requestId. Double tap to copy.',
    );
  }
}
