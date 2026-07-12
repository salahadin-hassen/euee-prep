import 'package:flutter/material.dart';

import '../../../../core/design/app_button.dart';
import '../../../../core/design/tokens.dart';
import '../widgets/stepper_app_bar.dart';

/// Step 1 — Confirm Purchase.
///
/// Read-only/instructional: no data entry, just clarity on what's being
/// bought before any payment instructions are shown. Subject list is
/// plain text (not cards) deliberately — this is a summary, not an
/// invitation to tap further, since the stream isn't purchased yet.
class Step1ConfirmPurchase extends StatelessWidget {
  const Step1ConfirmPurchase({
    super.key,
    required this.streamName,
    required this.subjects,
    required this.priceLabel,
    required this.onContinue,
  });

  final String streamName;
  final List<String> subjects;
  final String priceLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: StepperAppBar(
        title: 'Unlock $streamName',
        currentStep: 1,
        totalSteps: 4,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streamName Stream', style: AppTypography.typeHeading2),
              const SizedBox(height: AppSpacing.spaceMd),
              Text(
                subjects.join(' · '),
                style: AppTypography.typeBody.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              Text(
                'All Grade 9–12 content, downloadable, works offline',
                style: AppTypography.typeCaption,
              ),
              const SizedBox(height: AppSpacing.spaceLg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.colorSurface,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                  border: Border.all(color: AppColors.colorBorder),
                ),
                child: Text(
                  priceLabel,
                  style: AppTypography.typeHeading1,
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Continue',
                isFullWidth: true,
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
