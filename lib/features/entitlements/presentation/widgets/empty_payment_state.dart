import 'package:flutter/material.dart';

import '../../../../core/design/app_button.dart';
import '../../../../core/design/tokens.dart';

/// Shown on Payment History when the student has no payment requests
/// yet. Calm, single CTA — no dead-end, points directly at the
/// action that would create the first request.
class EmptyPaymentState extends StatelessWidget {
  const EmptyPaymentState({super.key, this.onBrowseSubjects});

  /// TODO(integration): wire to the main Subject list route once
  /// navigation is owned by the app shell.
  final VoidCallback? onBrowseSubjects;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: AppIconSize.iconSizeXl,
              color: AppColors.colorTextSecondary,
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            Text(
              'No payment requests yet',
              style: AppTypography.typeHeading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spaceXs),
            Text(
              'Unlock a stream to get started.',
              style: AppTypography.typeBody.copyWith(
                color: AppColors.colorTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            AppButton(
              label: 'Browse Subjects',
              onPressed: onBrowseSubjects,
            ),
          ],
        ),
      ),
    );
  }
}
