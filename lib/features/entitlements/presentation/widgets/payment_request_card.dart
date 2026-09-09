import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../models/payment_request_ui_model.dart';
import 'request_id_row.dart';
import 'status_badge.dart';
import 'unlock_cta_button.dart';

/// A single payment request entry in the Payment History list.
///
/// Visual language per the design review:
/// - Card background stays neutral (colorSurface) for every state —
///   only the left accent border and the StatusBadge carry state color.
///   This keeps the list calm rather than color-blocked, consistent
///   with the "never flashy" design philosophy even for the rejected
///   state.
/// - Rejected cards show a plain-language reason, never a raw admin
///   note or blank space. If [PaymentRequestUiModel.rejectionReason] is
///   null, fallback copy is shown instead of an empty section.
class PaymentRequestCard extends StatelessWidget {
  const PaymentRequestCard({
    super.key,
    required this.request,
    this.onGoToSubjects,
    this.onSubmitNewPayment,
  });

  final PaymentRequestUiModel request;
  final VoidCallback? onGoToSubjects;
  final VoidCallback? onSubmitNewPayment;

  Color get _accentColor => switch (request.status) {
        PaymentRequestStatus.rejected => AppColors.colorError,
        PaymentRequestStatus.entitled => AppColors.colorSuccess,
        _ => AppColors.colorBorder,
      };

  String get _timestampLabel {
    final isVerifiedLike = request.status == PaymentRequestStatus.entitled ||
        request.status == PaymentRequestStatus.verified;
    if (isVerifiedLike && request.verifiedAt != null) {
      return 'Verified ${_formatDate(request.verifiedAt!)}';
    }
    return 'Submitted ${_formatDate(request.submittedAt)}';
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = request.status == PaymentRequestStatus.rejected;

    return Semantics(
      container: true,
      label:
          '${request.streamName}, request ${request.requestId}, $_timestampLabel',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.colorSurface,
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
          border: Border(
            left:
                BorderSide(color: _accentColor, width: AppStroke.strokeAccent),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.streamName,
                    style: AppTypography.typeHeading3,
                  ),
                ),
                StatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: AppSpacing.spaceSm),
            RequestIdRow(requestId: request.requestId),
            Text(_timestampLabel, style: AppTypography.typeCaption),
            if (isRejected) ...[
              const SizedBox(height: AppSpacing.spaceSm),
              Text(
                request.rejectionReason?.trim().isNotEmpty == true
                    ? request.rejectionReason!
                    : "We couldn't verify this payment. Please check your "
                        'proof and try again.',
                style: AppTypography.typeBody,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (request.status == PaymentRequestStatus.entitled ||
                isRejected) ...[
              const SizedBox(height: AppSpacing.spaceMd),
              UnlockCtaButton(
                status: request.status,
                onGoToSubjects: onGoToSubjects,
                onSubmitNewPayment: onSubmitNewPayment,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
