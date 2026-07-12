import 'package:flutter/material.dart';

import '../../../../core/design/app_button.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/copyable_field.dart';
import '../widgets/stepper_app_bar.dart';

/// Step 2 — Payment Instructions.
///
/// Trust-critical screen. The payment number is copyable rather than
/// something the student has to transcribe by eye, and the CTA copy
/// ("I've Paid — Continue") is a deliberate lightweight commitment
/// checkpoint — it reduces the real failure mode of someone submitting
/// proof before they've actually completed the external payment.
class Step2PaymentInstructions extends StatelessWidget {
  const Step2PaymentInstructions({
    super.key,
    required this.priceLabel,
    required this.payToNumber,
    required this.payToName,
    required this.onContinue,
    this.onBack,
  });

  final String priceLabel;
  final String payToNumber;
  final String payToName;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: StepperAppBar(
        title: 'Payment Instructions',
        currentStep: 2,
        totalSteps: 4,
        onBack: onBack,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pay $priceLabel via Telebirr to:',
                style: AppTypography.typeBody,
              ),
              const SizedBox(height: AppSpacing.spaceMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spaceMd,
                ),
                decoration: BoxDecoration(
                  color: AppColors.colorSurface,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                  border: Border.all(color: AppColors.colorBorder),
                ),
                child: CopyableField(
                  value: payToNumber,
                  valueStyle: AppTypography.typeHeading2,
                ),
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              Text(
                'Account name: $payToName',
                style: AppTypography.typeCaption,
              ),
              const SizedBox(height: AppSpacing.spaceLg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: AppIconSize.iconSizeMd,
                    color: AppColors.colorWarning,
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  Expanded(
                    child: Text(
                      'Pay this amount exactly, then come back here to '
                      'submit your proof.',
                      style: AppTypography.typeBody.copyWith(
                        color: AppColors.colorWarning,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              AppButton(
                label: "I've Paid — Continue",
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
